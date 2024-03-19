// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMemeToken} from "./IMeme.sol";

/**
 * Just a Sample os a meme token
 * - With max tokens per wallet
 * - with renounce
 *
 */

contract MemeToken is IMemeToken, ERC20, Ownable {
    // Time to stop controll the maxWallet
    uint256 public immutable TIMESTAMP_DISABLE_MAX_WALLET_TOKENS; // = 1710885600; // 2024 March Tuesday 19, 22:00:00 UTC

    /// @dev Max amount of tokens anyone can buy to avoid very big wales
    uint256 public immutable MAX_WALLET_TOKENS;

    // 1 billion max
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000 * 10 ** DECIMALS;

    // DECIMALS
    uint8 public constant DECIMALS = 18;

    /// @dev Store main LP to avoid control max tokens for this address
    address private liquidityPoolAddress;

    constructor(
        uint256 _timestampDisableMaxWalletTokens,
        uint8 _maxWalletTokenPercentage
    ) ERC20("Meme Token", "MEME") Ownable(_msgSender()) {
        if (_maxWalletTokenPercentage == 0 || _maxWalletTokenPercentage > 100)
            revert MemeTokenInvalidPercentage(_maxWalletTokenPercentage);
        if (_timestampDisableMaxWalletTokens <= block.timestamp)
            revert MemeTokenInvalidTimestamp(block.timestamp, _timestampDisableMaxWalletTokens);

        // Mint all to sender
        _mint(_msgSender(), MAX_TOTAL_SUPPLY);

        // Set max transfer until defined timestamp
        MAX_WALLET_TOKENS = (MAX_TOTAL_SUPPLY * _maxWalletTokenPercentage) / 100;
        TIMESTAMP_DISABLE_MAX_WALLET_TOKENS = _timestampDisableMaxWalletTokens;
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier avoidWales(address _to, uint256 _amount) {
        if (block.timestamp <= TIMESTAMP_DISABLE_MAX_WALLET_TOKENS) {
            if (_to != liquidityPoolAddress) {
                if (balanceOf(_to) + _amount > MAX_WALLET_TOKENS)
                    revert MemeTokenInvalidAmount(
                        MAX_WALLET_TOKENS,
                        _amount,
                        TIMESTAMP_DISABLE_MAX_WALLET_TOKENS,
                        block.timestamp
                    );
            }
        }
        _;
    }

    /**
     * - OVERRIDE TRANSFER TO AVOID WALES
     */

    /// @dev Override the transfer function
    /// @notice Avoid transfer more than maxWalletToken
    /// @param to Destination address
    /// @param amount Amount to transfer
    function transfer(address to, uint256 amount) public virtual override avoidWales(to, amount) returns (bool) {
        return super.transfer(to, amount);
    }

    /// @dev Override the transfer function
    /// @notice Avoid transfer more than maxWalletToken
    /// @param from Origin address
    /// @param to Destination address
    /// @param amount Amount to transfer
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override avoidWales(to, amount) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    // Function to set the liquidity pool address
    function setLiquidityPoolAddress(address _liquidityPoolAddress) public onlyOwner {
        if (_liquidityPoolAddress == address(0)) revert MemeTokenLiquidityPoolCantBeZero();
        liquidityPoolAddress = _liquidityPoolAddress;
        emit LiquidityPoolAddressChanged(_liquidityPoolAddress);
    }
}
