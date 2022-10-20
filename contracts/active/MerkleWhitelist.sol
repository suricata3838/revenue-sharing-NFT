//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleWhitelist is Ownable {
  bytes32 public normalWhitelistMerkleRoot;
  bytes32 public specialWhitelistMerkleRoot;
  bytes32 public freeMintWhitelistMerkleRoot;

  string public whitelistURI;

  /*
  READ FUNCTIONS
  */

  //Frontend verify functions
  function verifyNormalSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, _hash(userAddress), normalWhitelistMerkleRoot);
  }

  function verifySpecialSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, _hash(userAddress), specialWhitelistMerkleRoot);
  }

  function verifyFreeMintSender(address userAddress, bytes32[] memory proof) public view returns (bool) {
    return _verify(proof, _hash(userAddress), freeMintWhitelistMerkleRoot);
  }

  //Internal verify functions
  function _verifyNormalSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), normalWhitelistMerkleRoot);
  }

  function _verifySpecialSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), specialWhitelistMerkleRoot);
  }

  function _verifyFreeMintSender(bytes32[] memory proof) internal view returns (bool) {
    return _verify(proof, _hash(msg.sender), freeMintWhitelistMerkleRoot);
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

  /*
  OWNER FUNCTIONS
  */

  function setNormalWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    normalWhitelistMerkleRoot = merkleRoot;
  }
  function setSpecialWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    specialWhitelistMerkleRoot = merkleRoot;
  }
  function setFreeMintWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    freeMintWhitelistMerkleRoot = merkleRoot;
  }
  /*
  MODIFIER
  */
  modifier onlyNormalWhitelist(bytes32[] memory proof) {
    require(_verifyNormalSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }

  modifier onlySpecialWhitelist(bytes32[] memory proof) {
    require(_verifySpecialSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
  
  modifier onlyFreeMintWhitelist(bytes32[] memory proof) {
    require(_verifyFreeMintSender(proof), "MerkleWhitelist: Caller is not whitelisted");
    _;
  }
}