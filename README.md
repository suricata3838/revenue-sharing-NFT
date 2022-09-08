# Donation-scheme NTF project
Project name will be reveiled when their public sale starts.

## Feature of project
- Donation NFT:
  - Distination is determined depending on the attribute type of each NFT.(ex, water -> NPO Ocean protect)
- Marketplace: Opensea
  - each time a NFT item is sold, revenue is shared to 3 entities; team, donation, and holders(past NFT holder of that NFT). HolderPass is a provenance of poof-of-hold of the NFT Token. Up to last 7 holders are available to receive the revenue.

## Technical feature of NFT
- Dynamic NFT:  NFT contract those tokenLevel is able to upgrade depending on the token sold price.
- RevenueBuffer at revenue-sharing:
  - max 10% revenue is distibuted to 3 eneities; team, donation, and holders at Opensea's creator earning.
  - in case of donation and holders, the RevenueBuffer contract is configured above.
  - `RevenueBuffer` stores all received ETH on the contract. Provider job posts Request to RevenueBuffer on the item sold event at Opensea. `RevenueBuffer` distibutes stored ETH to all requested receipients on being called with `batchWithdraw()` which only Provider role wallet can call.
- provider/index.js: Provider job
  - watch itemSoldEvent of Opensea
  - call request to `RevenueBuffer`
  - call upgradeTokenLEvel of `DynamicNFT`
  - call mint `HolderPassNFT` 

## Future work
- make all contract upgradable


## Basic Hardhat template
```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
