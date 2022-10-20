const {ethers, network} = require("hardhat");


async function main() {
    const [deployer] = await ethers.getSigners(network.config.accounts);
    const RevenueShare = await ethers.getContractFactory("RevenueShare");
    const revenueShare = await RevenueShare.connect(deployer).deploy();
    await revenueShare.deployed();

    console.log("Contract deployed to:", revenueShare.address, "from ", deployer.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });


// Memo: deploy and verify
//   npx hardhat run --network rinkeby ./scripts/deployRevenueSharing.js
//// Need to have artifacts before verification
//   npx hardhat compile --force
//   npx hardhat verify <deployed contract address> --network rinkeby