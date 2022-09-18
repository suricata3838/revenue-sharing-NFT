const { expect, use } = require('chai')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))

describe('WhitelistNFT', () => {
    it('Only allows whitelisted address to mintTokens()', async () => {
        const accounts = await ethers.getSigners()
        const whitelisted = accounts.slice(0, 5)
        const notWhitelisted = accounts.slice(5, 10)
        console.log(notWhitelisted[0].address);

        const padBuffer = (addr) => {
            // pad address with 0, and conver string(as hex) to Buffer
            return Buffer.from(addr.substr(2).padStart(32*2, 0), 'hex')
        }

        // prep tree and root
        const leaves = whitelisted.map(account => padBuffer(account.address))
        const tree = new MerkleTree(leaves, keccak256, { sort: true })
        const merkleRoot = tree.getHexRoot()// stored publically on smartcontract

        // prep badTree
        const badLeaves = notWhitelisted.map(account => padBuffer(account.address))
        const badTree = new MerkleTree(badLeaves, keccak256, { sort: true })

        // deploy WhitelistNFT
        const WhitelistNFT = await ethers.getContractFactory("WhitelistNFT")
        // constructor(merkleProof, maxTokens, maxMints)
        const whitelistNFT = await WhitelistNFT.deploy(merkleRoot, "10000", "5")
        await whitelistNFT.deployed();

        // prep merkleProof for whitelisted#0
        const merkleProof = tree.getHexProof(padBuffer(whitelisted[0].address))
        console.log("merkleProof:", merkleProof);
        // prep merkleProof for notWhitelisted#0
        const invalidMerkleProof = badTree.getHexProof(padBuffer(notWhitelisted[0].address))
        console.log("invalidMerkleProof:", invalidMerkleProof);

        await expect(whitelistNFT.mintTokens(merkleProof, "3")).to.not.be.rejected
        await expect(whitelistNFT.mintTokens(merkleProof, "3")).to.be.rejectedWith('No more claim')
        await expect(whitelistNFT.connect(notWhitelisted[0]).mintTokens(invalidMerkleProof, "3")).to.be.rejectedWith('Invalid MerkleProof')
    })
})