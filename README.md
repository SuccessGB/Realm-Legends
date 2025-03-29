# Realm Legends Platform

## Overview

Realm Legends is a decentralized gaming platform that enables players to truly own their in-game items through blockchain technology. Built on Stacks using Clarity smart contracts, Realm Legends allows for secure ownership, trading, and progression tracking within our fantasy gaming ecosystem.

## Features

- **True Ownership**: Players fully own their in-game items as blockchain assets
- **Secure Trading**: Built-in marketplace for buying and selling rare items
- **Character Progression**: On-chain tracking of character experience and levels
- **Transferable Items**: Trade eligible items with other players
- **Batch Operations**: Efficient multi-item minting and transfers

## Smart Contract Architecture

The platform is powered by a main smart contract that handles:

1. **Item Management**: Minting, ownership verification, and transfers
2. **Marketplace**: Listing, purchasing, and delisting game items
3. **Character Data**: Tracking player progression and achievements
4. **Access Control**: Ensuring only authorized users can perform sensitive operations

## Getting Started

### Prerequisites

- [Stacks Wallet](https://www.hiro.so/wallet)
- Basic understanding of blockchain transactions
- [Clarity SDK](https://github.com/hirosystems/clarinet) (for developers)

### For Players

1. Create a Stacks wallet
2. Connect your wallet to the Realm Legends platform
3. Start collecting items and building your character

### For Developers

```bash
# Clone the repository
git clone https://github.com/realm-legends/platform

# Install dependencies
npm install

# Run local development environment
npm run dev

# Deploy to testnet
npm run deploy:testnet
```

## Smart Contract Functions

### Item Management

- `mint-game-item`: Create a new game item (admin only)
- `batch-mint-game-items`: Create multiple game items at once (admin only)
- `transfer-game-item`: Transfer an item to another player
- `batch-transfer-game-items`: Transfer multiple items at once

### Marketplace

- `list-game-item-for-sale`: Make an item available for purchase
- `purchase-game-item`: Buy an item from the marketplace
- `delist-game-item`: Remove an item from sale

### Player Functions

- `update-character-progression`: Update a player's experience and level
- `get-character-progression`: View a player's stats

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only operation |
| u101 | Item not found |
| u102 | Not authorized |
| u103 | Invalid input |
| u104 | Invalid price |

## Security Considerations

- All marketplace transactions are atomic and secure
- Ownership verification prevents unauthorized transfers
- Built-in protections against common attack vectors

## Future Roadmap

- **Q2 2025**: Launch of Realm Legends Marketplace
- **Q3 2025**: Introduction of Legendary Items with special abilities
- **Q4 2025**: Guild system implementation
- **Q1 2026**: Cross-chain asset bridging

## Contributing

We welcome contributions from the community! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to get involved.

