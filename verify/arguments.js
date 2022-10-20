// const {arguments: argsNFT} = require('../scripts/deployNFT')
const {arguments: argsPass} = require('../scripts/deployHolderPass')

module.exports = [
    //...argsNFT,
    // ...argsPass,
    
]

/* How to deploy and verify */
// $npx hardhat compile --force
// $npx hardhat verify <deployed contract address> --constructor-args verify/arguments.js --network goerli