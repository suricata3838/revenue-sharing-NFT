const hre = require("hardhat");
const { keccak256, toUtf8Bytes } = hre.ethers.utils;
const { MerkleTree } = require('merkletreejs')

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
module.exports = {
    arguments
}

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
    console.log("dynamicWLNFT:", dynamicWLNFT.deployTransaction.hash);
    await dynamicWLNFT.deployed();
    console.log("Contract deployed to:", dynamicWLNFT.address, "from ", deployer.address);
}

const setupWL = async() => { 

    /* Whitelist Preparation*/
    const accounts = [
        "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
        "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
        "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
    ];
    const whitelisted = accounts.slice(0, 3)
    const notWhitelisted = accounts.slice(3, 4)
    const _hash = (_address) => {
        return keccak256(_address);
    }

    // prep tree and root
    const leaves = whitelisted.map(account => _hash(account))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()// stored publically on smartcontract
    console.log("merkleRoot:", merkleRoot);

    //get MerkleProof
    const merkleProof_0 = tree.getHexProof(_hash(whitelisted[0]))
    console.log("merkleProof_0:", merkleProof_0);
    const merkleProof_1 = tree.getHexProof(_hash(whitelisted[1]))
    console.log("merkleProof_1:", merkleProof_1);
    const merkleProof_2 = tree.getHexProof(_hash(whitelisted[2]))
    console.log("merkleProof_2:", merkleProof_2);
    
    // Verify
    console.log("leaves[0]:", leaves[0]);
    console.log("Result:", tree.verify(merkleProof_0, leaves[0], merkleRoot))
    console.log("leaves[1]:", leaves[1]);
    console.log("Result:", tree.verify(merkleProof_1, leaves[1], merkleRoot))

    /*Set MerkelProof*/
    // await dynamicWLNFT.setPublicWhitelistMerkleRoot(merkleRoot);
}

const main = async () => {
    try{
        // await deployDynamicWLNFT();
        await setupWL();
    }catch(e){
        console.error(e);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

//// Recent deployment contracts
// 0x9EE05d60d3FAf8735e9fd9CC68E3f9F25537Cd84