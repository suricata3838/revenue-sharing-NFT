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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFT is ERC721Enumerable, Ownable{
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
    ERC721 (name, symbol)
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        uint8 tokenLevel_ = tokenLevel[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "-", tokenLevel_.toString())) : "";
    }
    
    /* Main Sale with distination address*/
    function mintTokensTo(uint256 numberOfTokens, address _to) public payable {
        require(numberOfTokens <= MAX_MINTS, "Can only mint max purchase of tokens at a time");
        require(_to != address(0), "Invalid distination address");
        // totalSuply() is inherited from ERC721Enumerable.
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_TOKENS) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    /* for Airdrop */
    // TODO: update
    function airdrop(uint256 numberOfTokens) public payable {
        require(numberOfTokens <= MAX_MINTS, "Can only mint max purchase of tokens at a time");
        // totalSuply() is inherited from ERC721Enumerable.
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    /* Update tokenURI */
    function updateTokenLevel(uint256 tokenId, uint8 level) public onlyOwner {
        require(_exists(tokenId), "tokenId doesn't exist.");
        require(6 > level && level > tokenLevel[tokenId], "Invalid level");
        tokenLevel[tokenId] = level;
    }
}