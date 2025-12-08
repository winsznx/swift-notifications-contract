# Setup Guide

## Prerequisites
- Node.js (v14 or higher)
- npm or yarn

## Installation

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd swift-notifications-contract
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Configuration
- Copy `.env.example` to `.env` and fill in the required values.

## Running Tests
```bash
npx hardhat test
```

## Deployment
```bash
npx hardhat run scripts/deploy.js --network <network-name>
```
