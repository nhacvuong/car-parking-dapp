# Celo Car Parking Dapp

## Description
This is a very simple car parking dapp where users can:
* Park/Un-park user's car with cUSD and pay the owner.
* See user's car parked on the Celo Blockchain

## Live Demo
[CarParking Dapp](https://nhacvuong.github.io/car-parking-dapp/)

## Usage

### Requirements
1. Install the [CeloExtensionWallet](https://chrome.google.com/webstore/detail/celoextensionwallet/kkilomkmpmkbdnfelcpgckmpcaemjcdh?hl=en) from the Google Chrome Store.
2. Create a wallet.
3. Go to [https://celo.org/developers/faucet](https://celo.org/developers/faucet) and get tokens for the alfajores testnet.
4. Switch to the alfajores testnet in the CeloExtensionWallet.

### Test
1. Create two accounts.
2. Park a car using first account.
3. Switch to second account, and you will not see the parked car from first account.
4. Park another car using second account. You could not park the same car number with first account.
5. Un-park the car and send owner cUSD tokens.
6. Check if balance of second account decreased.

## Project Setup

### Install
```
npm install
```

### Start
```
npm run dev
```

### Build
```
npm run build
