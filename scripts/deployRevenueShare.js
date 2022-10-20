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

/*
 * Recent contract address on Goerli
 **/
// RevenueShare: 0xDF685944d8dbaBDdF01bC60a96957F04bb8359E3