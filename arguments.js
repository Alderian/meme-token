// JavaScript module that exports the constructor as an argument list
// Required by the Hardhat plugin `hardhat-etherscan`
// See also here: https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html#complex-arguments

// ARGUMENTS
// Percentage ot total supply that any wallet can buy 
const maxWalletTokenPercentage = 1;

// eslint-disable-next-line no-undef
module.exports = [
  maxWalletTokenPercentage,
];
