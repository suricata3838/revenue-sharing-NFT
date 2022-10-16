const {arguments} = require('../scripts/deployNFT')

module.exports = [
    arguments
]

/* How to deploy and verify */
// $npx hardhat compile --force
// $npx hardhat verify <deployed contract address> --constructor-args verify/arguments.js --network goerli