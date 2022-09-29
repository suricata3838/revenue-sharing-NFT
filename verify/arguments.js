module.exports = [
    "MitamaTest",
    "MTM",
    "https://gateway.pinata.cloud/ipfs/QmXMJo4qPdobEfL75ChQFpNTm6z1DrBzNZwgtXJSmReRXx/",
    /* BigNumber is converted to String */
    "100000000000000000",
    "100",
    "5"
]

/* How to deploy and verify */
// $npx hardhat compile --force
// $npx hardhat verify <deployed contract address> --constructor-args verify/arguments.js --network rinkeby