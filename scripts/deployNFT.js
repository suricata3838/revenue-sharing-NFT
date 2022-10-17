const hre = require("hardhat");

const name = "Dynamic";
const symbol = "DM";
const baseURI = "https://gateway.pinata.cloud/ipfs/QmXMJo4qPdobEfL75ChQFpNTm6z1DrBzNZwgtXJSmReRXx/";
const tokenPrice = hre.ethers.utils.parseEther("0.1"); //float?
const maxTokens = 100;
const maxMints = 5;

const arguments = [
    name,
    symbol,
    baseURI,
    tokenPrice,
    maxTokens,
    maxMints
]
// async function deployDynamicNFT() {
//     const [deployer] = await hre.ethers.getSigners();
//     const DynamicNFT = await hre.ethers.getContractFactory("DynamicNFT");
//     const dynamicNFT = await DynamicNFT.deploy(
//         name, symbol, baseURI, tokenPrice, maxTokens, maxMints);
//     await dynamicNFT.deployed();
//     console.log("Contract deployed to:", dynamicNFT.address, "from ", deployer.address);
// }

async function deployDynamicWLNFT() {
    const [deployer] = await hre.ethers.getSigners();
    const DynamicWLNFT = await hre.ethers.getContractFactory("DynamicWLNFT");
    const dynamicWLNFT = await DynamicWLNFT.deploy(
        name, symbol, baseURI, tokenPrice, maxTokens, maxMints);
    console.log("dynamicWLNFT:", dynamicWLNFT);
    await dynamicWLNFT.deployed();
    console.log("Contract deployed to:", dynamicWLNFT.address, "from ", deployer.address);
}

const setupWL = async() => { 

    /* Whitelist Preparation*/
    const accounts = await hre.ethers.getSigners()
    const whitelisted = accounts.slice(0, 5) //only[deployer]account
    console.log("whitelisted:", whitelisted);
    const notWhitelisted = accounts.slice(5, 10)// nothing
    console.log("notWhitelisted:", notWhitelisted);
    console.log(notWhitelisted[0].address);// nothing
    const padBuffer = (addr) => {
        // pad address with 0, and conver string(as hex) to Buffer
        return Buffer.from(addr.substr(2).padStart(32*2, 0), 'hex')
    }
    // prep tree and root
    const leaves = whitelisted.map(account => padBuffer(account.address))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()// stored publically on smartcontract

    /*Set MerkelProof*/
    // await dynamicWLNFT.setPublicWhitelistMerkleRoot(merkleRoot);
}

const main = async () => {
    try{
        await deployDynamicWLNFT();
        // await setupWL();
    }catch(e){
        console.error(e);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });


module.exports = {
    arguments
}