const {ethers, network} = require("hardhat");
const { BigNumber } = require("bignumber.js");
const { utils } = require("ethers");
const materialIdList = require("../__file/materialIdList.json");
const dotenv  = require ("dotenv");
dotenv.config();
const { ETH_APIKEY, PRIVKEY } = process.env;

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

const getSigner = () => {
  const network = ethers.providers.getNetwork("mainnet");
  const alchemyProvider = new ethers.providers.AlchemyProvider(network, ETH_APIKEY);
  const signer = new ethers.Wallet(PRIVKEY, alchemyProvider);
  return signer;
}

const getContract = (_signer, address, abi) => {
  const contractInst = new ethers.Contract(address, abi.abi, _signer);
  const contractInstAddr = contractInst.attach(address);
  return contractInstAddr;
}

const RevenueShareForDonationAbi = require ("../artifacts/contracts/active/RevenueShareForDonation.sol/RevenueShareForDonation.json");
// Mumbai testnet
// const RevenueShareForDonationAddress = '0x32A9b2c4Ef7ac84f39962834AB795dC2B181a21A';
// Mainnet
const RevenueShareForDonationAddress = '0x1CDE6E7f0BB09FFD40e366cAd206a663D81614b3';

async function setTokenMaterial() {
  const signer =  getSigner();
  const revenueShareForDonation = getContract(
    signer,
    RevenueShareForDonationAddress, 
    RevenueShareForDonationAbi
  );
  const addrss =  await signer.getAddress();
  const feeData = await ethers.provider.getFeeData()
  const nonce = await signer.getTransactionCount()
  const gasLimit = await revenueShareForDonation.estimateGas.setTokenToMaterial(materialIdList.slice(0, 500), 0, {
    from: addrss
  })

  console.log("feeData.maxFeePerGas:", feeData.maxFeePerGas.toString());
  console.log("feeData.maxFeePerGas:", feeData.maxPriorityFeePerGas.toString());
  console.log("gasLimit:", gasLimit);

  // done: [0]
  // for (let i = 1; i < 2; i++) {
    let i = 1;
    try {
      console.log(`try ${i}`);
      const tx = await revenueShareForDonation.setTokenToMaterial(materialIdList.slice(i * 500, (i + 1) * 500), i);
        // { maxFeePerGas: new BigNumber(feeData.maxFeePerGas.toString()).multipliedBy(new BigNumber("1.5")).toString(),
          // maxPriorityFeePerGas: new BigNumber(feeData.maxPriorityFeePerGas.toString()).multipliedBy(new BigNumber("1.5")).toString(),
          // gasLimit: gasLimit.mul(2).toString(),
          // nonce: nonce + i
        // });
      await tx.wait()
      console.log(`done: ${i}: ${tx.hash}`) 
    }catch(e){
      console.log(JSON.parse(e.error.error.body).error.message)
    }
  // }
}

const testCalc = () => {
  const buf = new BigNumber("1.5")
  console.log(typeof(buf));
  const bufbuf = buf.multipliedBy(buf);
  console.log(bufbuf);
}

async function main() {
  try {
  // await deployRevenueShare();
  // await deployRevenueShareForDonation();
  await setTokenMaterial();
  // testCalc();
  } catch(e) {
    console.log(e)
  }

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

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