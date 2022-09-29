//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleWhitelist is Ownable {
  bytes32 public publicWhitelistMerkleRoot;
  // bytes32 public mouseWhitelistMerkleRoot;

  string public whitelistURI;

  /*
  READ FUNCTIONS
  */

  //Frontend verify functions
  function verifyPublicSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, toBytes32(userAddress), publicWhitelistMerkleRoot);
  }

  //Internal verify functions
  function _verifyPublicSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, toBytes32(msg.sender), publicWhitelistMerkleRoot);
  }

  function _verify(bytes32[] memory proof, bytes32 addressHash, bytes32 whitelistMerkleRoot)
    internal
    pure
    returns (bool)
  {
    return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
  }

  function _hash(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address));
  }

  function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
  }

  /*
  OWNER FUNCTIONS
  */

  function setPublicWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    publicWhitelistMerkleRoot = merkleRoot;
  }

  /*
  MODIFIER
  */
  modifier onlyPublicWhitelist(bytes32[] memory proof) {
    require(_verifyPublicSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}