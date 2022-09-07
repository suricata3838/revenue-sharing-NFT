// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

///////////////////////////////////////////////////////////////////////////////
//  ___ ___  ____  ______   ____  ___ ___   ____      ____    ____  _____ _____
// |   T   Tl    j|      T /    T|   T   T /    T    |    \  /    T/ ___// ___/
// | _   _ | |  T |      |Y  o  || _   _ |Y  o  |    |  o  )Y  o  (   \_(   \_ 
// |  \_/  | |  | l_j  l_j|     ||  \_/  ||     |    |   _/ |     |\__  T\__  T
// |   |   | |  |   |  |  |  _  ||   |   ||  _  |    |  |   |  _  |/  \ |/  \ |
// |   |   | j  l   |  |  |  |  ||   |   ||  |  |    |  |   |  |  |\    |\    |
// l___j___j|____j  l__j  l__j__jl___j___jl__j__j    l__j   l__j__j \___j \___j
//                                                                            
///////////////////////////////////////////////////////////////////////////////

// MitamaHolderPass is ERC721.

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HolderNFT is ERC721A, Ownable{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint8;

    // Token data
    uint256 public TOKEN_PRICE;
    uint256 public MAX_TOKENS;
    uint256 public MAX_MINTS;

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
        uint256 maxMints   
    )
    ERC721A (name, symbol)
    {
        setBaseURI(baseURI);
        setTokenPrice(tokenPrice);
        setMaxTokens(maxTokens);
        setMaxMints(maxMints);
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
    
    /* Main Sale with distination address*/
    function mintTokens(uint256 numberOfTokens, address _to) public payable {
        require(_to != address(0), "Invalid distination addresse");
        require(numberOfTokens <= MAX_MINTS, "Can only mint max purchase of tokens at a time");
        // totalSuply() is inherited from ERC721Enumerable.
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        // ERC721A's _mint(to, quantity)
        _mint(_to, numberOfTokens);
    }
}