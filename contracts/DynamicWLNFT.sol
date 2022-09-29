// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

////////////////////////////////////////////
// ___  ________ _____ ___  ___  ___  ___  
// |  \/  |_   _|_   _/ _ \ |  \/  | / _ \ 
// | .  . | | |   | |/ /_\ \| .  . |/ /_\ \
// | |\/| | | |   | ||  _  || |\/| ||  _  |
// | |  | |_| |_  | || | | || |  | || | | |
// \_|  |_/\___/  \_/\_| |_/\_|  |_/\_| |_/
//
////////////////////////////////////////////

// MitamaTest is Dynamic ERC721
// each tokenId has 6 upgradable image and attibute on this matadata.

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DynamicNFT is ERC721A, Ownable{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint8;

    // Token data
    uint256 public TOKEN_PRICE;
    uint256 public MAX_TOKENS;
    uint256 public MAX_MINTS;
    mapping(address => uint256) public claimedAmount;
    bytes32 immutable public merkleRoot;


    // Metadata
    string public _baseTokenURI;

    // tokenLevel of tokenId
    mapping(uint256 => uint8) public tokenLevel;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 tokenPrice,
        uint256 maxTokens,
        uint256 maxMints,
        bytes32 _merkleRoot
    )
    ERC721A (name, symbol)
    {
        setBaseURI(baseURI);
        setTokenPrice(tokenPrice);
        setMaxTokens(maxTokens);
        setMaxMints(maxMints);
        merkleRoot = _merkleRoot;
    }

    /* ERC721 Setters */
    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setTokenPrice(uint256 tokenPrice_) public onlyOwner {
        TOKEN_PRICE = tokenPrice_;
    }

    function setMaxTokens(uint256 maxTokens_) public onlyOwner {
        MAX_TOKENS = maxTokens_;
    }

    function setMaxMints(uint256 maxMints_) public onlyOwner {
        MAX_MINTS = maxMints_;
    }

    /* ERC721 Getters */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* ERC721 primitive */
    // TODO: set metadata json files on IPFS and get CID
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");

        string memory baseURI = _baseURI();
        uint8 tokenLevel_ = tokenLevel[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "-", tokenLevel_.toString())) : "";
    }
    
    /* Main Sale */
    function mintTokens(uint256 numberOfTokens) public payable {
        require(claimedAmount[msg.sender] + numberOfTokens <= MAX_MINTS, "No more claim");
        // totalSuply() is inherited from ERC721Enumerable.
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        // ERC721A's _mint(to, quantity)
        _mint(msg.sender, numberOfTokens);
    }

    /* Mint for WL */
    function mintWLTokens(bytes32[] calldata merkleProof, uint256 numberOfTokens) public payable {
        require(claimedAmount[msg.sender] + numberOfTokens <= MAX_MINTS, "No more claim");
        claimedAmount[msg.sender] += numberOfTokens;
        require(MerkleProof.verify(merkleProof, merkleRoot, toBytes32(msg.sender)), "Invalid MerkleProof");
        _mint(msg.sender, numberOfTokens);
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /* Update tokenURI */
    function updateTokenLevel(uint256 tokenId, uint8 level) public onlyOwner {
        require(_exists(tokenId), "tokenId doesn't exist.");
        require(6 > level && level > tokenLevel[tokenId], "Invalid level");
        tokenLevel[tokenId] = level;
    }
}