// ARGUMENTS
// GMT	Tue Mar 19 2024 22:00:00 GMT+0000
const TIMESTAMP_DISABLE_MAX_WALLET_TOKENS = 1710885600;
// Percentage ot total supply that any wallet can buy until TIMESTAMP_DISABLE_MAX_WALLET_TOKENS
const maxWalletTokenPercentage = 1;

// Input the arguments for the constructor
const data = [TIMESTAMP_DISABLE_MAX_WALLET_TOKENS, maxWalletTokenPercentage];
// Export the arguments to be picked up by the `hardhat.config.ts` deployment script
export { data };
