# 🎨 Tokenised Artisan Market

A decentralized NFT marketplace specifically designed for artisans to mint, list, and sell their handcrafted works as non-fungible tokens on the Stacks blockchain.

## ✨ Features

- 🎭 **Artisan Profiles**: Create and verify artisan profiles with bio and reputation tracking
- 🖼️ **NFT Minting**: Mint artwork as NFTs with metadata and royalty settings
- 💰 **Marketplace**: List, buy, and trade artisan NFTs with automatic fee distribution
- 👑 **Royalty System**: Creators earn royalties on secondary sales
- 🔒 **Admin Controls**: Contract owner can pause/unpause and verify artisans
- 📊 **Reputation Tracking**: Track sales history and reputation scores

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) for testing
- Stacks wallet for interaction

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Tokenised-Artisan-Market-
```

2. Install dependencies:
```bash
npm install
```

3. Check the contract:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## 📋 Contract Functions

### 👤 Artisan Management

#### `create-artisan-profile`
Create an artisan profile with name and bio.
```clarity
(contract-call? .tokenised-artisan-market create-artisan-profile "Artist Name" "Bio description")
```

#### `verify-artisan`
(Admin only) Verify an artisan profile.
```clarity
(contract-call? .tokenised-artisan-market verify-artisan 'SP1ARTISAN...)
```

### 🎨 NFT Operations

#### `mint-artwork`
Mint a new artwork NFT with metadata and royalty percentage (max 20%).
```clarity
(contract-call? .tokenised-artisan-market mint-artwork 
  "Artwork Name" 
  "Description of the artwork" 
  "https://image-url.com/artwork.jpg" 
  "Painting" 
  u500) ;; 5% royalty
```

#### `transfer-artwork`
Transfer NFT ownership to another user.
```clarity
(contract-call? .tokenised-artisan-market transfer-artwork u1 tx-sender 'SP2RECIPIENT...)
```

### 🛒 Marketplace Operations

#### `list-for-sale`
List an NFT for sale at a specific price (in microSTX).
```clarity
(contract-call? .tokenised-artisan-market list-for-sale u1 u1000000) ;; 1 STX
```

#### `unlist-from-sale`
Remove an NFT from marketplace listings.
```clarity
(contract-call? .tokenised-artisan-market unlist-from-sale u1)
```

#### `buy-artwork`
Purchase a listed NFT (automatically handles fees and royalties).
```clarity
(contract-call? .tokenised-artisan-market buy-artwork u1)
```

### 🔧 Admin Functions

#### `set-platform-fee`
(Admin only) Set platform fee percentage (max 10%).
```clarity
(contract-call? .tokenised-artisan-market set-platform-fee u300) ;; 3%
```

#### `pause-contract` / `unpause-contract`
(Admin only) Pause or unpause contract operations.
```clarity
(contract-call? .tokenised-artisan-market pause-contract)
(contract-call? .tokenised-artisan-market unpause-contract)
```

### 📖 Read-Only Functions

#### `get-token-metadata`
Retrieve NFT metadata by token ID.
```clarity
(contract-call? .tokenised-artisan-market get-token-metadata u1)
```

#### `get-listing`
Get marketplace listing information for a token.
```clarity
(contract-call? .tokenised-artisan-market get-listing u1)
```

#### `get-artisan-profile`
Retrieve artisan profile information.
```clarity
(contract-call? .tokenised-artisan-market get-artisan-profile 'SP1ARTISAN...)
```

#### `get-contract-info`
Get general contract information (owner, fees, pause status, total tokens).
```clarity
(contract-call? .tokenised-artisan-market get-contract-info)
```

## 💸 Fee Structure

- **Platform Fee**: 2.5% by default (configurable up to 10%)
- **Royalty Fee**: Set by creator (up to 20%)
- **Fee Distribution**: Platform fee goes to contract owner, royalty fee goes to original creator

## 🛡️ Security Features

- ✅ Ownership verification for all operations
- ✅ Pause mechanism for emergency stops
- ✅ Input validation for all parameters
- ✅ Protection against self-transfers
- ✅ Automatic delisting when transferring

## 📊 Data Structures

### Token Metadata
```clarity
{
  name: (string-ascii 64),
  description: (string-ascii 256), 
  image-uri: (string-ascii 256),
  creator: principal,
  created-at: uint,
  category: (string-ascii 32)
}
```

### Market Listing
```clarity
{
  seller: principal,
  price: uint,
  listed-at: uint,
  active: bool
}
```

### Artisan Profile
```clarity
{
  name: (string-ascii 64),
  bio: (string-ascii 256),
  verified: bool,
  total-sales: uint,
  reputation-score: uint
}
```

## 🔢 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-NOT-AUTHORIZED | Caller not authorized |
| u101 | ERR-TOKEN-NOT-FOUND | Token or profile not found |
| u102 | ERR-NOT-OWNER | Caller not token owner |
| u103 | ERR-INVALID-PRICE | Invalid price (must be > 0) |
| u104 | ERR-NOT-LISTED | Token not listed for sale |
| u105 | ERR-INSUFFICIENT-FUNDS | Not enough funds |
| u106 | ERR-CONTRACT-PAUSED | Contract is paused |
| u107 | ERR-INVALID-ROYALTY | Royalty percentage too high |
| u108 | ERR-SELF-TRANSFER | Cannot transfer to self |
| u109 | ERR-INVALID-FEE | Fee percentage too high |

## 🧪 Testing

Run the test suite:
```bash
npm test
```

Run specific tests:
```bash
npm test -- --grep "mint artwork"
```

## 📝 Development

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract locally:
```clarity
::deploy_contract contracts/Tokenised-Artisan-Market-.clar
```

3. Test functions interactively in the console.

### Contract Structure

- **NFT Token**: `artisan-work` - The main NFT token
- **Data Variables**: Contract state management
- **Maps**: Storage for metadata, listings, profiles, and royalties
- **Functions**: Public and private functions for all operations
- **Traits**: NFT trait implementation for standard compliance



## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built on the Stacks blockchain
- Powered by Clarity smart contracts
- Inspired by the vibrant artisan community

---

**Made with ❤️ for artisans worldwide** 🌍

