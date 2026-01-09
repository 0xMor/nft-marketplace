# NFT Marketplace

A decentralized NFT Marketplace built with Solidity and Hardhat. This project allows users to mint, list, and buy NFTs, featuring platform fees and creator royalties.

## Features

- **Minting**: Create new NFTs (ERC-721).
- **Listing**: List NFTs for sale at a specific price.
- **Buying**: Purchase NFTs securely.
- **Royalties**: Automatic royalty payments to the original creator on secondary sales.
- **Platform Fees**: Configurable fee sent to the marketplace owner upon each sale.
- **Security**: Protected against reentrancy attacks using OpenZeppelin's `ReentrancyGuard`.

## Technology Stack

- **Solidity** (v0.8.28)
- **Hardhat** (Development environment)
- **Ethers.js v6** (Blockchain interaction)
- **OpenZeppelin** (Standard secure contracts)
- **Chai** (Testing)

## Prerequisites

- **Node.js**: Please use an **LTS version** (v18 or v20).
  > **Note:** Avoid using Node.js v24+ ("Current") as it may cause stability issues with Hardhat on Windows.

## Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/YOUR_USERNAME/nft-marketplace.git](https://github.com/YOUR_USERNAME/nft-marketplace.git)
   cd nft-marketplace
