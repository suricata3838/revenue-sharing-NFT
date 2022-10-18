// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//////////////////////////////////
//  ____   ____  _____ _____
// |    \ /    |/ ___// ___/
// |  o  )  o  (   \_(   \_ 
// |   _/|     |\__  |\__  |
// |  |  |  _  |/  \ |/  \ |
// |  |  |  |  |\    |\    |
// |__|  |__|__| \___| \___|                       
//                                                                            
//////////////////////////////////

// HolderPass is ERC1155.

import { ERC165, IERC165, ERC165Storage }  from "@solidstate/contracts/introspection/ERC165.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { AccessControl } from "@solidstate/contracts/access/access_control/AccessControl.sol";
import { EnumerableSet } from "@solidstate/contracts/utils/EnumerableSet.sol";
import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";
import { ERC1155EnumerableStorage } from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";
import "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HolderPass is SolidStateERC1155, AccessControl {
    using ERC165Storage for ERC165Storage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;


    // Token informations
    string public name;
    string public symbol;
    string public contractURI;
    uint256 public MAX_NUMBER = 3;
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI
    ) {
        ERC165Storage.layout().setSupportedInterface(
            type(IERC165).interfaceId,
            true
        );
        ERC165Storage.layout().setSupportedInterface(
            type(IERC1155).interfaceId,
            true
        );

        ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();
        l.baseURI = _contractURI;
        name = _name;
        symbol = _symbol;
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mintPass(
        address account,
        uint256 id
    ) external onlyRole(MINTER_ROLE)  {
        if(totalSupply(id) > MAX_NUMBER) {
            address secondPassHolder = _addrByIndex(id, 1);
            _burn(secondPassHolder, id, 1); 
        }
        _mint(account, id, 1, '');
    }

    function burn(
        address account,
        uint256 id
    ) external onlyRole(MINTER_ROLE) {
        _burn(account, id, 1);
    }

    function setContractURI(string calldata _uri) external onlyRole(MINTER_ROLE) {
        contractURI = _uri;
    }

    /**
     * @notice query idx of account who owns token id
     * @param id: token id, addr: address
     * @return index of Account
     */
    function indexOfAddr(uint256 id, address addr)
        external
        view
        returns (uint256)
    {
        // TODO: if accounts is the list of account, not index.
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        // checker: contains 
        // value => index
        require(accounts.contains(addr), "Invalid Index");
        return accounts.indexOf(addr);
    }

    function addrByIndex(uint256 id, uint256 index)
        external
        view
        returns (address)   
    {
        return _addrByIndex(id, index);
    }

    /**
     * @notice query idx of account who owns token id
     * @param id: token id, addr: address
     * @return index of Account
     */
    function _addrByIndex(uint256 id, uint256 index)
        internal
        view
        returns (address)
    {
        EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage
            .layout()
            .accountsByToken[id];

        // value => index
        require(accounts.length() > index, "Invalid index");
        return accounts.at(index);
    }



}