// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Just a Sample os a meme token
 * - With max tokens per wallet
 * - with renounce
 *
 */

interface IMemeToken {
    /**
     * @dev Emitted when new Liquidity pool has been set to `newLiquidityPoolAddress`
     */
    event LiquidityPoolAddressChanged(address indexed newLiquidityPoolAddress);

    /**
     * @dev Emitted when new max wallet transfer amount has been set to `newMaxWalletAmount`.
     */

    event MaxWalletAmountChanged(uint256 newMaxWalletAmount);

    /**
     * @dev Indicates an error related to the percentage of max tokens per wallet. Min 0, max 100.
     * @param percentage Wanted percentaje.
     */
    error MemeTokenInvalidPercentage(uint256 percentage);

    /**
     * @dev Indicates an error related to the timestamp. It neds to be higher
     * @param current Current timestamp.
     * @param wanted Wanted timestamp.
     */
    error MemeTokenInvalidTimestamp(uint256 current, uint256 wanted);

    /**
     * @dev Indicates an error related to the amount you want to transfer while limit is enforced.
     * @param limit Current amount limit.
     * @param amount Wanted transfer amount.
     * @param liquidityPool Allowed destination
     * @param to actual destination.
     */
    error MemeTokenInvalidAmount(uint256 limit, uint256 amount, address liquidityPool, address to);

    /**
     * @dev Indicates an error related to the Liquidity Pool. It needs to be different to Zero Address
     */
    error MemeTokenLiquidityPoolCantBeZero();
}
