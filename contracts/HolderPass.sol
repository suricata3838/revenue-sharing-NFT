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
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";
import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

contract Pass is SolidStateERC1155, AccessControl {

    // Token informations
    string public name;
    string public symbol;
    string public contractURI;
    using ERC165Storage for ERC165Storage.Layout;
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
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
        symbol = _symbol;

    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE){
        _mint(account, id, amount, '');
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _burn(account, id, amount);
    }

    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}