require ("@nomiclabs/hardhat-ethers");
require ("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  etherscan: {
    apiKey: {
      polygon: "W38RH21ZF3K4MA6MJU34V5WA5D3B72BV88"
    }
  }
};
