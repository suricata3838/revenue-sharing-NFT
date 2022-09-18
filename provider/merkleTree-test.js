const assert = require('assert');
const { MerkleTree } = require('merkletreejs')
const SHA256 = require('crypto-js/sha256')

const list = ['a', 'b', 'c']
const leaves = list.map(x => SHA256(x))
const tree = new MerkleTree(leaves, SHA256, {sort: true})
const treeUnsorted = new MerkleTree(leaves, SHA256)
const root = tree.getRoot().toString('hex');
const hexRoot = tree.getHexRoot()
const leafa = SHA256('a');
const leafb = SHA256('b');
const proofa = tree.getProof(leafa);
const hexProofA = tree.getHexProof(leafa);
const proofb = tree.getProof(leafb);
const hexProofB = tree.getHexProof(leafb);

assert.equal('0x'+root, hexRoot);
// if set to sort, hex verification is true.
console.log(tree.verify(hexProofA, leafa, hexRoot));// true
// console.log(tree.toString())
// └─ 8fee4b5ecf296a85922864113a5b1f05df4a3cc7ff94921309b68f285dfa1cef
//    ├─ 749b7ca2a54111005e8fd558804ff78333d14b32de9bb15efb5ab282c4dadc81
//    │  ├─ 2e7d2c03a9507ae265ecf5b5356885a53393a2029d241394997265a1a25aefc6
//    │  └─ 3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d
//    └─ ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb
//       └─ ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb
// console.log(treeUnsorted.toString())
// └─ 7075152d03a5cd92104887b476862778ec0c87be5c2fa1c0a90f87c49fad6eff
//    ├─ e5a01fee14e0ed5c48714f22180f25ad8365b53f9779f79dc4a3d7e93963f94a
//    │  ├─ ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb
//    │  └─ 3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d
//    └─ 2e7d2c03a9507ae265ecf5b5356885a53393a2029d241394997265a1a25aefc6
//       └─ 2e7d2c03a9507ae265ecf5b5356885a53393a2029d241394997265a1a25aefc6
