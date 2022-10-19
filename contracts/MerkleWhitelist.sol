//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleWhitelist is Ownable {
  bytes32 public NormalWhitelistMerkleRoot;
  // bytes32 Normal mouseWhitelistMerkleRoot;

  string public whitelistURI;

  /*
  READ FUNCTIONS
  */

  //Frontend verify functions
  function verifyNormalSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, toBytes32(userAddress), NormalWhitelistMerkleRoot);
  }

  //Internal verify functions
  function _verifyNormalSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, toBytes32(msg.sender), NormalWhitelistMerkleRoot);
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

  function setNormalWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    NormalWhitelistMerkleRoot = merkleRoot;
  }

  /*
  MODIFIER
  */
  modifier onlyNormalWhitelist(bytes32[] memory proof) {
    require(_verifyNormalSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}