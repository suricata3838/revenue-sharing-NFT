const {ethers, network} = require("hardhat");
const materialIdList = require("../_file/materialIdList.json");

async function deployRevenueShare() {
    const [deployer] = await ethers.getSigners(network.config.accounts);
    const RevenueShare = await ethers.getContractFactory("RevenueShare");
    const revenueShare = await RevenueShare.connect(deployer).deploy();
    await revenueShare.deployed();

    console.log("revenueShare deployed to:", revenueShare.address, "from ", deployer.address);
}
/**
 * material type to order convertion:
 */
  // Diamond => 1,
  // Fire => 2,
  // Fluffy => 3, 
  // Glow => 4,
  // Liquid => 5,
  // Matte => 6,
  // Metal => 7

async function deployRevenueShareForDonation() {
  const [deployer] = await ethers.getSigners(network.config.accounts);
  const RevenueShareForDonation = await ethers.getContractFactory("RevenueShareForDonation");
  const revenueShareForDonation = await RevenueShareForDonation.connect(deployer).deploy();
  await revenueShareForDonation.deployed();
  console.log("revenueShareForDonation deployed to:", revenueShareForDonation.address, "from ", deployer.address);
}

async function setTokenMaterial() {
  const address = "";
  const revenueShareForDonation = "";
  for (let i = 0; i < 18; i++) {
    const tx = await revenueShareForDonation.setTokenToMaterial(materialIdList.slice(i * 500, (i + 1) * 500), i);
    await tx.wait()
    console.log(`done: ${i}: ${tx.hash}`)
}  
}

async function main() {
  try {
  // await deployRevenueShare();
  await deployRevenueShareForDonation();
  // await setTokenMaterial();
  } catch(e) {
    console.error(e)
  }

}

// main().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
//   });

module.exports = [
  materialIdList
]
/*
 * Ehtereum mainnet
 **/
// RevenueShare: https://etherscan.io/address/0x811BC1fFC4a198F90193D91729ca4ab90241E940#code
// RevenueShareForDonation: https://etherscan.io/address/0x1CDE6E7f0BB09FFD40e366cAd206a663D81614b3#code

/**
 * Mumbai testnet
 */
// RevenueShareForDonation: https://mumbai.polygonscan.com/address/0x32A9b2c4Ef7ac84f39962834AB795dC2B181a21A#code