// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

///////////////////////////////////////////////
// ___  ___ _____  _____   ___  ___  ___  ___  
// |  \/  ||_   _||_   _| / _ \ |  \/  | / _ \ 
// | .  . |  | |    | |  / /_\ \| .  . |/ /_\ \
// | |\/| |  | |    | |  |  _  || |\/| ||  _  |
// | |  | | _| |_   | |  | | | || |  | || | | |
// \_|  |_/ \___/   \_/  \_| |_/\_|  |_/\_| |_/
// 
///////////////////////////////////////////////

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MerkleWhitelist.sol";
import "hardhat/console.sol";

contract Mitama is ERC721A, Ownable, MerkleWhitelist{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint8;

    /**
     * Mitama Dutch Auction configration: configured by the team at deployment.
     */
    uint256 public DA_STARTING_PRICE = 0.6 ether;
    uint256 public DA_ENDING_PRICE = 0.1 ether;
    // Decrement 0.05 ether every 1.5 hours ~= 0.00005 ether every 5 sec.
    uint256 public DA_DECREMENT = 0.00005 ether;
    uint256 public DA_DECREMENT_FREQUENCY = 5;
    // Mint starts: Sunday, October 30, 2022 9:00:00 PM GMT+09:00: 1667131200
    uint256 public DA_STARTING_TIMESTAMP = 1667131200;
    uint256 public DA_QUANTITY = TOKEN_QUANTITY - 1000 - FREE_MINT_QUANTITY;// 8580
    // wait 1 week: 
    uint256 public WAITING_FINAL_WITHDRAW = 60*60*24*7;
    // Withdraw address
    address public TEAM_WALLET = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    /**
     * Mitama NFT configuration: configured by the team at deployment.
     */
    uint256 public TOKEN_QUANTITY = 10000;
    uint256 public FREE_MINT_QUANTITY = 420;
    // TODO: update all MAX_MINTS
    uint256 public MAX_MINTS_PUBLIC = 1;
    uint256 public MAX_MINTS_NORMAL_WL = 2;
    uint256 public MAX_MINTS_SPECIAL_WL = 1;
    uint256 public DISCOUNT_PERCENT_NORMAL_WL = 10;
    uint256 public DISCOUNT_PERCENT_SPECIAL_WL = 30;
    
    /**
     * Internal storages for Dutch Auction
     */
    uint256 public DA_FINAL_PRICE;
    // How many each WL have been minted
    uint16 public NORMAL_WL_MINTED;
    uint16 public SPECIAL_WL_MINTED;
    // Withdraw status
    bool public INITIAL_FUNDS_WITHDRAWN;
    bool public REMAINING_FUNDS_WITHDRAWN;
    // Event:
    event DAisFinishedAtPrice(uint256 finalPrice);
    //Struct for storing batch price data.
    struct TokenBatchPrice {
        uint128 pricePaid;
        uint8 quantityMinted;
    }
    //userAddress to token price data
    mapping(address => TokenBatchPrice[]) public userToTokenBatchPrices;
    mapping(address => TokenBatchPrice[]) public normalWLToTokenBatchPrices;
    mapping(address => TokenBatchPrice[]) public specialWLToTokenBatchPrices;
    mapping(address => bool) public userToHasMintedFreeMint;

    /**
     * Internal storages for NFT Collection
     */
    // tokenURI
    string public baseURI;
    string public UNREVEALED_URI;
    bool public REVEALED;
    // auraLevel by tokenId
    mapping(uint256 => uint8) public auraLevel;

    /**
     * Initializate contract
     */

    constructor(
        string memory _unrevealedURI
    ) ERC721A ('Mitama', 'MTM') {
        setRevealData(false, _unrevealedURI);
    }
    
    /**
     * Mint
     */

    function currentPrice() public view returns (uint256) {
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        //Seconds since we started
        uint256 timeSinceStart = block.timestamp - DA_STARTING_TIMESTAMP;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;

        //How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return DA_STARTING_PRICE - totalDecrement;
    }

    function mintDAPublic (uint8 quantity) public payable {
        bool res = canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_NORMAL_WL, userToTokenBatchPrices);
        if(!res) console.log("Invalid mint request");
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }
    
    function mintDANormalWL(bytes32[] calldata merkleProof, uint8 quantity)
        public
        payable 
        onlyNormalWhitelist(merkleProof)
    {
        require(
            canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_SPECIAL_WL, normalWLToTokenBatchPrices),
            "Invalid mint request"
        );
        NORMAL_WL_MINTED += quantity;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }


    /* Mint for Special WL */
    function mintSpecialWL(bytes32[] calldata merkleProof, uint8 quantity)
        public
        payable 
        onlySpecialWhitelist(merkleProof) //TODO
    {
        require(
            canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_PUBLIC, specialWLToTokenBatchPrices),
            "Invalid mint request"
        );
        SPECIAL_WL_MINTED += quantity;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }

    function freeMint(bytes32[] memory proof)
        public
        onlyFreeMintWhitelist(proof) //TODO
    {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");
        require(
            !userToHasMintedFreeMint[msg.sender],
            "Can only mint one time!"
        );

        //Require max supply just in case.
        require(totalSupply() + 1 <= TOKEN_QUANTITY, "Exceeds max supply!");

        userToHasMintedFreeMint[msg.sender] = true;

        //Mint them
        _safeMint(msg.sender, 1);
    }
    
    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        //Max supply
        require(
            totalSupply() + quantity <= TOKEN_QUANTITY,
            "Max supply of 10,000 total!"
        );

        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        //Mint the quantity
        _safeMint(receiver, quantity);
    }

    /**
     * Refund and Withdraw
     */

    function withdrawInitialFunds() public onlyOwner nonReentrant {
        require(
            !INITIAL_FUNDS_WITHDRAWN,
            "Initial funds have already been withdrawn."
        );
        require(DA_FINAL_PRICE > 0, "DA has not finished!");

        uint256 DAFunds = DA_QUANTITY * DA_FINAL_PRICE;
        uint256 normalWLRefund = NORMAL_WL_MINTED *
            ((DA_FINAL_PRICE / 100) * 20);
        uint256 specialWLRefund = SPECIAL_WL_MINTED *
            ((DA_FINAL_PRICE / 100) * 20);
        
        uint256 initialFunds = DAFunds - normalWLRefund - specialWLRefund;
        console.log("initialFunds:", initialFunds);

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(TEAM_WALLET).call{
            value: initialFunds
        }("");
        require(succ, "transfer failed");
    }

    function withdrawFinalFunds() public onlyOwner nonReentrant {
        //Require this is 1 weeks after DA Start.
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP + WAITING_FINAL_WITHDRAW, 
            "Until the time have passed since DA started."
        );

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(TEAM_WALLET).call{
            value: finalFunds
        }("");
        console.log("finalFunds:", finalFunds);
        require(succ, "transfer failed");
    }

    /* Refund by owner */
    function refundExtraETH() public nonReentrant {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 publicRefund = _getRefund(msg.sender, userToTokenBatchPrices, 0);
        uint256 normalWLRefund = _getRefund(msg.sender, normalWLToTokenBatchPrices, DISCOUNT_PERCENT_NORMAL_WL);
        uint256 specialWLRefund = _getRefund(msg.sender, specialWLToTokenBatchPrices, DISCOUNT_PERCENT_SPECIAL_WL);
        uint256 totalRefund = publicRefund + normalWLRefund + specialWLRefund;
        console.log("totalRefund:", totalRefund);
        require(address(this).balance > totalRefund, "Contract runs out of funds.");
        payable(msg.sender).transfer(totalRefund);

    }

    function _getRefund(
        address user,
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices,
        uint256 _DISCOUNT_PERCENT
    ) internal returns (uint256) {
        TokenBatchPrice[] storage tokenBatchPrices = _userToTokenBatchPrices[user];
        uint256 totalRefund;
        for (
            uint256 i = tokenBatchPrices.length;
            i > 0;
            i--
        ) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = tokenBatchPrices[i - 1]
                .quantityMinted * DA_FINAL_PRICE * (100 - _DISCOUNT_PERCENT) / 100;

            //What they paid - what they should have paid = refund.
            uint256 refund = tokenBatchPrices[i - 1]
                .pricePaid - expectedPrice;

            //Remove this tokenBatch
            tokenBatchPrices.pop();

            //Send them their extra monies.
            totalRefund += refund;
        }
        return totalRefund;
    }


    /**
     * Update NFT's AuraLevel
     */
    function updateAuraLevel(uint256 tokenId, uint8 level) public onlyOwner {
        require(_exists(tokenId), "tokenId doesn't exist.");
        require(6 > level && level > auraLevel[tokenId], "Invalid level");
        auraLevel[tokenId] = level;
    }

    /**
     * Internal functions for Dutch Auction
     */

    function canMintDA(
        address user,
        uint256 amount,
        uint8 quantity, 
        uint256 _MAX_MINT,
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices
    ) internal returns (bool) {
        //Require DA started
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );

        console.log("length:", _userToTokenBatchPrices[user].length);

        //Require max is up to MAX_MINTS_PUBLIC
        require(
            quantity > 0 && quantity + _sumOfQuantityMinted(_userToTokenBatchPrices, user) <= _MAX_MINT,
            "Quantity exceeds max mintable!"
        );

        uint256 _currentPrice = currentPrice();

        //Require enough ETH
        require(
            amount >= quantity * _currentPrice,
            "Insufficient amount to mint."
        );

        //Max supply
        require(
            totalSupply() + quantity <= DA_QUANTITY,
            "Max supply for DA reached!"
        );

        //This is the final price
        if (totalSupply() + quantity == DA_QUANTITY) {
            DA_FINAL_PRICE = _currentPrice;
            emit DAisFinishedAtPrice(DA_FINAL_PRICE);
        }

        _userToTokenBatchPrices[user].push(
            TokenBatchPrice(uint128(amount), quantity)
        );

        return true;
    }

    function _sumOfQuantityMinted(
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices,
        address userAddr
    ) internal view returns (uint256) {
        TokenBatchPrice[] memory batchPriceList = _userToTokenBatchPrices[userAddr];
        uint256 sumOfQuantityMinted;
        if(batchPriceList.length == 0) return 0;
        for(uint256 i=0; i < batchPriceList.length; i++){
            sumOfQuantityMinted += batchPriceList[i].quantityMinted;
        }
        return sumOfQuantityMinted;
    }

    function _userToTokenBatchLength(
        address user,
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices
    )
        internal
        view
        returns (uint256)
    {
        return _userToTokenBatchPrices[user].length;
    }
    
    /**
     * House keeping funcitons
     */
    
    /* ERC721 Setters */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    
    function setRevealData(bool _revealed, string memory _unrevealedURI)
        public
        onlyOwner
    {
        REVEALED = _revealed;
        UNREVEALED_URI = _unrevealedURI;
    }

    /* ERC721 primitive */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");
        uint8 auraLevel_ = auraLevel[tokenId];
        if (REVEALED){
            return bytes(baseURI).length > 0 
                ? string(abi.encodePacked(baseURI, tokenId.toString(), "-", auraLevel_.toString())) 
                : "";
        } else {
            return UNREVEALED_URI;           
        }
    }

    /* get the number of user who has minted*/
    function userToTokenBatchLength(address user)
        public
        view
        returns (uint256)
    {
        return _userToTokenBatchLength(user, userToTokenBatchPrices);
    }

    function normalWLToTokenBatchLength(address user)
        public
        view
        returns (uint256)
    {
        return _userToTokenBatchLength(user, normalWLToTokenBatchPrices);
    }

    function specialWLToTokenBatchLength(address user)
        public
        view
        returns (uint256)
    {
        return _userToTokenBatchLength(user, specialWLToTokenBatchPrices);
    }
}