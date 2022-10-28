const hre = require("hardhat");
const { keccak256 } = hre.ethers.utils;
const { MerkleTree } = require('merkletreejs')

// TODO* NEED "/" at the last of baseURI!
const test_baseURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/pinata/Mitama_dir/";
const test_unrevealedURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/ipfs/Mitama_dir/egg_meta";
const unrevealedURI = "https://gateway.pinata.cloud/ipfs/QmYhT8vFpz4bq6QCaRDzei6w4X8AbwTrbutvxPJ3HexUeN"
// const unrevealedURI = "ipfs://QmYhT8vFpz4bq6QCaRDzei6w4X8AbwTrbutvxPJ3HexUeN";

const arguments = unrevealedURI;
module.exports = [arguments];

async function deployMitama() {
    const [deployer] = await hre.ethers.getSigners();
    const Mitama = await hre.ethers.getContractFactory("Mitama");
    const mitama = await Mitama.deploy(unrevealedURI); 
    console.log("Mitama txHash:", mitama.deployTransaction.hash);
    await mitama.deployed();
    console.log("Contract deployed to:", mitama.address, "from ", deployer.address);
}

async function deployMitamaTest() {
    const [deployer] = await hre.ethers.getSigners();
    const Mitama = await hre.ethers.getContractFactory("Mitama"); 
    const mitama = await Mitama.deploy(test_unrevealedURI);
    console.log("Mitama txHash:", mitama.deployTransaction.hash);
    await mitama.deployed();
    console.log("Contract deployed to:", mitama.address, "from ", deployer.address);
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

const verify = async() => {
    await hre.run(`verify:verify`, { 
        address: "0x40f5434cbED8ac30a0A477a7aFc569041B3d2012", 
        constructorArguments: [unrevealedURI], 
      });
}

const main = async () => {
    try{
        // await deployMitama();
        // await deployMitamaTest();
        // await verify();
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
 * Recent contract address on Mumbai
 **/
//  Mitama: https://mumbai.polygonscan.com/address/0x1CDE6E7f0BB09FFD40e366cAd206a663D81614b3#code