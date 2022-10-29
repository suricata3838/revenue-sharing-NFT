const {ethers, network} = require("hardhat");
const dotenv  = require ("dotenv");
dotenv.config();
const { ETH_APIKEY, PRIVKEY } = process.env;

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

const MitamaAbi = require ("../artifacts/contracts/active/Mitama.sol/Mitama.json");
// Mainnet
const MitamaAddress = '0x40f5434cbED8ac30a0A477a7aFc569041B3d2012';