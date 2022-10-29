const hre = require("hardhat");
const { keccak256 } = hre.ethers.utils;
const { MerkleTree } = require('merkletreejs')

// TODO* NEED "/" at the last of baseURI!
const test_baseURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/pinata/Mitama_dir/";
const test_unrevealedURI = "https://raw.githubusercontent.com/suricata3838/revenue-sharing-NFT/main/ipfs/Mitama_dir/egg_meta";
// const unrevealedURI = "https://gateway.pinata.cloud/ipfs/QmYhT8vFpz4bq6QCaRDzei6w4X8AbwTrbutvxPJ3HexUeN"
const unrevealedURI = "ipfs://QmVQcu2Q1YEBVAWEJd1HvQbR6ndrwU6e5Aq5n2WxtRtxDY";

const arguments = test_unrevealedURI;
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
    const Mitama = await hre.ethers.getContractFactory("MitamaTest"); 
    const mitama = await Mitama.deploy(test_unrevealedURI);
    console.log("Mitama txHash:", mitama.deployTransaction.hash);
    await mitama.deployed();
    console.log("Contract deployed to:", mitama.address, "from ", deployer.address);
}

const setupWL = async() => { 

    /* Whitelist Preparation*/
    const accounts = [
        "0xcDe7a88a1dada60CD5c888386Cc5C258D85941Dd", //Norika
        "0xabf54b4da815309cB17055c7D4E5a31cDE5f1aBe",
        "0x0Fb59f9E958c13f99fadF0062d4E2BAe6b38aEe8",
        "0x78879eaB33D4CB076799a84209fe028E7CFeAbfB",
        "0x4a5906151959d06B2b469f74Ce9084F6c1F723C5",
        "0xAadf31D980aEa12A68A4080Ff0E21E0Eeb4f116D"
    ];
    const _hash = (_address) => {
        return keccak256(_address);
    }

    // prep tree and root
    const leaves = accounts.map(account => _hash(account))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()// stored publically on smartcontract
    console.log("merkleRoot:", merkleRoot);

    //get MerkleProof
    const merkleProof_0 = tree.getHexProof(_hash(accounts[0]))
    console.log("merkleProof_0:", merkleProof_0);
    const merkleProof_1 = tree.getHexProof(_hash(accounts[1]))
    console.log("merkleProof_1:", merkleProof_1);
    const merkleProof_2 = tree.getHexProof(_hash(accounts[2]))
    console.log("merkleProof_2:", merkleProof_2);
    const merkleProof_3 = tree.getHexProof(_hash(accounts[3]))
    console.log("merkleProof_3:", merkleProof_3);
    const merkleProof_4 = tree.getHexProof(_hash(accounts[4]))
    console.log("merkleProof_4:", merkleProof_4);
    const merkleProof_5 = tree.getHexProof(_hash(accounts[5]))
    console.log("merkleProof_5:", merkleProof_5);

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
        await setupWL();
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
//  Mitama: https://mumbai.polygonscan.com/address/0x228746DE5026286ff7403dfafbF08BE70e08cf67
// CheapMitama: https://mumbai.polygonscan.com/address/0xC31331f24207f2FaBe69172D29751eE5ccb38D25#code

/**
 * Mainnet
 */
// https://etherscan.io/address/0x40f5434cbED8ac30a0A477a7aFc569041B3d2012#code