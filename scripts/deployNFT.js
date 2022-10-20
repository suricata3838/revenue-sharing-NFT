const hre = require("hardhat");
const { keccak256, toUtf8Bytes } = hre.ethers.utils;
const { MerkleTree } = require('merkletreejs')

const baseURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/pinata/Mitama_dir/";
const unrevealedURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/pinata/Mitama_dir/unreleave";

const arguments = [baseURI, unrevealedURI];
module.exports = {
    arguments
}

async function deployTestDAWLNFT() {
    const [deployer] = await hre.ethers.getSigners();
    const TestDAWLNFT = await hre.ethers.getContractFactory("TestDAWLNFT");
    const testDAWLNFT = await TestDAWLNFT.deploy(baseURI, unrevealedURI);
    console.log("testDAWLNFT:", testDAWLNFT.deployTransaction.hash);
    await testDAWLNFT.deployed();
    console.log("Contract deployed to:", testDAWLNFT.address, "from ", deployer.address);
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
        await deployTestDAWLNFT();
        // await setupWL();
    }catch(e){
        console.error(e);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/*
 * Recent contract address on Goerli
 **/
//  DAWLNFT: 0xcDe7a88a1dada60CD5c888386Cc5C258D85941Dd