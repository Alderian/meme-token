// JavaScript module that exports the constructor as an argument list
// Required by the Hardhat plugin `hardhat-etherscan`
// See also here: https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html#complex-arguments

// ARGUMENTS
const TIMESTAMP_DISABLE_MAX_WALLET_TOKENS = Date.now() / 1000 + 60 * 60 * 1; // Now + 1 hour
// Percentage ot total supply that any wallet can buy until TIMESTAMP_DISABLE_MAX_WALLET_TOKENS
const maxWalletTokenPercentage = 1;

// eslint-disable-next-line no-undef
module.exports = [
  TIMESTAMP_DISABLE_MAX_WALLET_TOKENS,
  maxWalletTokenPercentage,
];
