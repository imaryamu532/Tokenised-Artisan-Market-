(define-trait nft-trait (
    (get-last-token-id
        ()
        (response uint uint)
    )
    (get-token-uri
        (uint)
        (response (optional (string-ascii 256)) uint)
    )
    (get-owner
        (uint)
        (response (optional principal) uint)
    )
    (transfer
        (uint principal principal)
        (response bool uint)
    )
))

(define-non-fungible-token artisan-work uint)

(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var platform-fee-percentage uint u250)
(define-data-var is-paused bool false)

(define-map token-metadata
    uint
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        image-uri: (string-ascii 256),
        creator: principal,
        created-at: uint,
        category: (string-ascii 32),
    }
)

(define-map market-listings
    uint
    {
        seller: principal,
        price: uint,
        listed-at: uint,
        active: bool,
    }
)

(define-map artisan-profiles
    principal
    {
        name: (string-ascii 64),
        bio: (string-ascii 256),
        verified: bool,
        total-sales: uint,
        reputation-score: uint,
    }
)

(define-map token-royalties
    uint
    {
        creator: principal,
        royalty-percentage: uint,
    }
)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-TOKEN-NOT-FOUND (err u101))
(define-constant ERR-NOT-OWNER (err u102))
(define-constant ERR-INVALID-PRICE (err u103))
(define-constant ERR-NOT-LISTED (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-CONTRACT-PAUSED (err u106))
(define-constant ERR-INVALID-ROYALTY (err u107))
(define-constant ERR-SELF-TRANSFER (err u108))
(define-constant ERR-INVALID-FEE (err u109))

(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)

(define-private (calculate-fee
        (amount uint)
        (fee-percentage uint)
    )
    (/ (* amount fee-percentage) u10000)
)

(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-fee u1000) ERR-INVALID-FEE)
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

(define-public (pause-contract)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set is-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set is-paused false)
        (ok true)
    )
)

(define-public (create-artisan-profile
        (name (string-ascii 64))
        (bio (string-ascii 256))
    )
    (begin
        (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
        (map-set artisan-profiles tx-sender {
            name: name,
            bio: bio,
            verified: false,
            total-sales: u0,
            reputation-score: u100,
        })
        (ok true)
    )
)

(define-public (verify-artisan (artisan principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (match (map-get? artisan-profiles artisan)
            profile (begin
                (map-set artisan-profiles artisan
                    (merge profile { verified: true })
                )
                (ok true)
            )
            ERR-TOKEN-NOT-FOUND
        )
    )
)

(define-public (mint-artwork
        (name (string-ascii 64))
        (description (string-ascii 256))
        (image-uri (string-ascii 256))
        (category (string-ascii 32))
        (royalty-percentage uint)
    )
    (let ((token-id (+ (var-get last-token-id) u1)))
        (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (<= royalty-percentage u2000) ERR-INVALID-ROYALTY)
        (try! (nft-mint? artisan-work token-id tx-sender))
        (map-set token-metadata token-id {
            name: name,
            description: description,
            image-uri: image-uri,
            creator: tx-sender,
            created-at: stacks-block-height,
            category: category,
        })
        (map-set token-royalties token-id {
            creator: tx-sender,
            royalty-percentage: royalty-percentage,
        })
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

(define-public (list-for-sale
        (token-id uint)
        (price uint)
    )
    (begin
        (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (> price u0) ERR-INVALID-PRICE)
        (asserts! (is-eq (some tx-sender) (nft-get-owner? artisan-work token-id))
            ERR-NOT-OWNER
        )
        (map-set market-listings token-id {
            seller: tx-sender,
            price: price,
            listed-at: stacks-block-height,
            active: true,
        })
        (ok true)
    )
)

(define-public (unlist-from-sale (token-id uint))
    (begin
        (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
        (match (map-get? market-listings token-id)
            listing (begin
                (asserts! (is-eq tx-sender (get seller listing))
                    ERR-NOT-AUTHORIZED
                )
                (map-set market-listings token-id
                    (merge listing { active: false })
                )
                (ok true)
            )
            ERR-NOT-LISTED
        )
    )
)

(define-public (buy-artwork (token-id uint))
    (let (
            (listing (unwrap! (map-get? market-listings token-id) ERR-NOT-LISTED))
            (price (get price listing))
            (seller (get seller listing))
            (platform-fee (calculate-fee price (var-get platform-fee-percentage)))
            (royalty-info (default-to {
                creator: seller,
                royalty-percentage: u0,
            }
                (map-get? token-royalties token-id)
            ))
            (royalty-fee (calculate-fee price (get royalty-percentage royalty-info)))
            (seller-amount (- (- price platform-fee) royalty-fee))
        )
        (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (get active listing) ERR-NOT-LISTED)
        (asserts! (not (is-eq tx-sender seller)) ERR-SELF-TRANSFER)
        (try! (stx-transfer? price tx-sender seller))
        (if (> platform-fee u0)
            (try! (stx-transfer? platform-fee seller (var-get contract-owner)))
            true
        )
        (if (and (> royalty-fee u0) (not (is-eq seller (get creator royalty-info))))
            (try! (stx-transfer? royalty-fee seller (get creator royalty-info)))
            true
        )
        (try! (nft-transfer? artisan-work token-id seller tx-sender))
        (map-set market-listings token-id (merge listing { active: false }))
        (match (map-get? artisan-profiles seller)
            profile (map-set artisan-profiles seller
                (merge profile { total-sales: (+ (get total-sales profile) u1) })
            )
            true
        )
        (ok true)
    )
)

(define-public (transfer-artwork
        (token-id uint)
        (sender principal)
        (recipient principal)
    )
    (begin
        (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq sender recipient)) ERR-SELF-TRANSFER)
        (match (map-get? market-listings token-id)
            listing (if (get active listing)
                (map-set market-listings token-id
                    (merge listing { active: false })
                )
                true
            )
            true
        )
        (nft-transfer? artisan-work token-id sender recipient)
    )
)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (some (get image-uri
        (default-to {
            name: "",
            description: "",
            image-uri: "",
            creator: (var-get contract-owner),
            created-at: u0,
            category: "",
        }
            (map-get? token-metadata token-id)
        ))))
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? artisan-work token-id))
)

(define-read-only (get-token-metadata (token-id uint))
    (map-get? token-metadata token-id)
)

(define-read-only (get-listing (token-id uint))
    (map-get? market-listings token-id)
)

(define-read-only (get-artisan-profile (artisan principal))
    (map-get? artisan-profiles artisan)
)

(define-read-only (get-contract-info)
    {
        owner: (var-get contract-owner),
        platform-fee: (var-get platform-fee-percentage),
        is-paused: (var-get is-paused),
        total-tokens: (var-get last-token-id),
    }
)
