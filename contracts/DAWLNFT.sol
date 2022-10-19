// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//////////////////////////////////////////////////////////////////////
// 
// ██████╗  █████╗       ███████╗██████╗  ██████╗███████╗██████╗  ██╗
// ██╔══██╗██╔══██╗      ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║
// ██║  ██║███████║█████╗█████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║
// ██║  ██║██╔══██║╚════╝██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║
// ██████╔╝██║  ██║      ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║
// ╚═════╝ ╚═╝  ╚═╝      ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝                              
// 
//////////////////////////////////////////////////////////////////////
// MitamaTest is ERC721 which accepts Dutch Auction as the minting approach.


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleWhitelist.sol";

contract DAWLNFT is ERC721A, Ownable, MerkleWhitelist{
    using SafeMath for uint256;
    using Strings for uint256;
    using Strings for uint8;

    /**
     * Mitama Dutch Auction configuration
     */
    uint256 public DA_STARTING_PRICE = 0.6 ether;
    uint256 public DA_ENDING_PRICE = 0.1 ether;
    // Decrement 0.05 ether every 3 hours = 0.001 ether every 216 sec
    uint256 public DA_DECREMENT = 0.001 ether;
    uint256 public DA_DECREMENT_FREQUENCY = 216;
    // Mint starts: Sunday, October 30, 2022 9:00:00 PM GMT+09:00
    uint256 public DA_STARTING_TIMESTAMP = 1667131200;
    uint256 public DA_FINAL_PRICE;
    uint256 public DA_QUANTITY = 8580;
    // How many each WL have been minted
    uint16 public NORMAL_WL_MINTED;
    uint16 public SPECIAL_WL_MINTED;
    // Withdraw status
    bool public INITIAL_FUNDS_WITHDRAWN;
    bool public REMAINING_FUNDS_WITHDRAWN;
    // Event:
    event DAisFinishedAtPrice(uint256 finalPrice);

    /**
     * Mitama NFT Collection
     */
    uint256 public TOKEN_QUANTITY = 10000;
    uint256 public FREE_MINT_QUANTITY = 420;
    // TODO: update all MAX_MINTS
    uint256 public MAX_MINTS_PUBLIC = 5;
    uint256 public MAX_MINTS_NORMAL_WL = 5;
    uint256 public MAX_MINTS_SPECIAL_WL = 5;
    uint256 public DISCOUNT_PERCENT_NORMAL_WL = 10 ;
    uint256 public DISCOUNT_PERCENT_SPECIAL_WL = 30 ;
    mapping(address => uint256) public claimedAmount;

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

    // withdrawal Address
    // TODO: update
    address public TEAM_WALLET = 0xcDe7a88a1dada60CD5c888386Cc5C258D85941Dd;

    // tokenURI
    string public baseURI;
    string public UNREVEALED_URI;
    bool public REVEALED;

    // tokenLevel of tokenId
    mapping(uint256 => uint8) public tokenLevel;

    constructor(
        string memory _baseURI, string memory _unrevealedURI
    ) ERC721A ('DAERC721', 'DA') {
        setBaseURI(_baseURI);
        setRevealData(false, _unrevealedURI);
    }
    
    /**
     * mint
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
        require(
            canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_PUBLIC, userToTokenBatchPrices),
            "Invalid mint request"
        );
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }
    
    function mintDANormalWL(bytes32[] calldata merkleProof, uint8 quantity)
        public
        payable 
        onlyNormalWhitelist(merkleProof)
    {
        require(
            canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_PUBLIC, normalWLToTokenBatchPrices),
            "Invalid mint request"
        );
        NORMAL_WL_MINTED++;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }


    /* Mint for Special WL */
    function mintSpecialWL(bytes32[] calldata merkleProof, uint8 quantity)
        public
        payable 
        onlyNormalWhitelist(merkleProof) //TODO
    {
        require(
            canMintDA(msg.sender, msg.value, quantity, MAX_MINTS_PUBLIC, specialWLToTokenBatchPrices),
            "Invalid mint request"
        );
        SPECIAL_WL_MINTED++;
        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }

    function freeMint(bytes32[] memory proof)
        public
        onlyNormalWhitelist(proof) //TODO
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

    /**
     * refund and withdraw
     */

    function withdrawInitialFunds() public onlyOwner {
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

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(TEAM_WALLET).call{
            value: initialFunds
        }("");
        require(succ, "transfer failed");
    }

    function withdrawFinalFunds() public onlyOwner {
        //Require this is 1 weeks after DA Start.
        require(block.timestamp >= DA_STARTING_TIMESTAMP + 604800);

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(TEAM_WALLET).call{
            value: finalFunds
        }("");
        require(succ, "transfer failed");
    }

    /* Refund by owner */
    function refundExtraETH() public {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 publicRefund = _getRefund(msg.sender, userToTokenBatchPrices, 0);
        uint256 normalWLRefund = _getRefund(msg.sender, normalWLToTokenBatchPrices, DISCOUNT_PERCENT_NORMAL_WL);
        uint256 specialWLRefund = _getRefund(msg.sender, specialWLToTokenBatchPrices, DISCOUNT_PERCENT_SPECIAL_WL);
        uint256 totalRefund = publicRefund + normalWLRefund + specialWLRefund;
        // payable: transfer ETH from this contract to others
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
     * Update NFT's Aura
     */
    function updateTokenLevel(uint256 tokenId, uint8 level) public onlyOwner {
        require(_exists(tokenId), "tokenId doesn't exist.");
        require(6 > level && level > tokenLevel[tokenId], "Invalid level");
        tokenLevel[tokenId] = level;
    }

    /**
     * Internal functions for dutch auction
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

        //Require max is up to MAX_MINTS_PUBLIC
        require(
            quantity > 0 && _sumOfQuantityMinted(_userToTokenBatchPrices, user) + quantity < _MAX_MINT,
            "Quantity exceeds max mintable!"
        );

        uint256 _currentPrice = currentPrice();

        //Require enough ETH
        require(
            msg.value >= quantity * _currentPrice,
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

        userToTokenBatchPrices[user].push(
            TokenBatchPrice(uint128(amount), quantity)
        );

        return true;
    }

    function _sumOfQuantityMinted(
        mapping(address => TokenBatchPrice[]) storage _userToTokenBatchPrices,
        address userAddr
    ) internal view returns (uint256) {
        uint256 sumOfQuantityMinted;
        if(_userToTokenBatchPrices[userAddr][0].pricePaid > 0) return 0;
        TokenBatchPrice[] memory batchPriceList = _userToTokenBatchPrices[userAddr];
        for(uint256 i; i < batchPriceList.length; i++){
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
        uint8 tokenLevel_ = tokenLevel[tokenId];
        if (REVEALED){
            return bytes(baseURI).length > 0 
                ? string(abi.encodePacked(baseURI, tokenId.toString(), "-", tokenLevel_.toString())) 
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