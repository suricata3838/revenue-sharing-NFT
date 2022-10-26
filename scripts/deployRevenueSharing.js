const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const RevenueShare = await ethers.getContractFactory("RevenueShare");
  const revenueShare = await upgrades.deployProxy(RevenueShare, [], {
    initializer: "__RevenueShare_init",
  });
  await revenueShare.deployed();

  console.log(
    "Contract proxy deployed to:",
    revenueShare.address,
    "from ",
    deployer.address
  );
  const adminAddress = await upgrades.erc1967.getAdminAddress(
    revenueShare.address
  );

  console.log("Admin address:", adminAddress);

  const implAddress = await upgrades.erc1967.getImplementationAddress(
    revenueShare.address
  );

  console.log("RevenueShare implementation address:", implAddress);
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
