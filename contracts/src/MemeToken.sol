// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMemeToken} from "./IMemeToken.sol";

/**
 * Just a Sample os a meme token
 * - With max tokens per wallet
 * - with renounce
 *
 */

contract MemeToken is IMemeToken, ERC20, Ownable {
    /// @dev Max amount of tokens anyone can buy to avoid very big wales
    uint256 private _maxWalletTokens;

    // 1 billion max
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000 * 10 ** DECIMALS;

    // DECIMALS
    uint8 public constant DECIMALS = 18;

    /// @dev Store main LP to avoid control max tokens for this address
    address private liquidityPoolAddress;

    /**
     * @dev constructor
     * @param _maxWalletTokenPercentage set the percentage from 1% to 100%
     */
    constructor(uint8 _maxWalletTokenPercentage) ERC20("Meme Token With permit", "MEME") Ownable(_msgSender()) {
        if (_maxWalletTokenPercentage == 0 || _maxWalletTokenPercentage > 100)
            revert MemeTokenInvalidPercentage(_maxWalletTokenPercentage);

        // Set max transfer until defined timestamp
        _maxWalletTokens = (MAX_TOTAL_SUPPLY * _maxWalletTokenPercentage) / 100;

        // Allow msg.sender to get all supply
        liquidityPoolAddress = _msgSender();

        // Mint all to sender
        _mint(_msgSender(), MAX_TOTAL_SUPPLY);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Overriding _update() method to avoid wales buy/sell/transfer until we think its safe
     */
    function _update(address from, address to, uint256 value) internal override {
        if (to != liquidityPoolAddress) {
            if (balanceOf(to) + value > _maxWalletTokens)
                revert MemeTokenInvalidAmount(_maxWalletTokens, value, liquidityPoolAddress, to);
        }
        super._update(from, to, value);
    }

    // Function to set the liquidity pool address
    function setLiquidityPoolAddress(address _liquidityPoolAddress) public onlyOwner {
        if (_liquidityPoolAddress == address(0)) revert MemeTokenLiquidityPoolCantBeZero();
        liquidityPoolAddress = _liquidityPoolAddress;
        emit LiquidityPoolAddressChanged(_liquidityPoolAddress);
    }

    /**
     * @dev Get current max tokens per wallet
     */
    function maxWalletTokens() public view returns (uint256) {
        return _maxWalletTokens;
    }

    /**
     * @dev Set max wallet tokens percentage. From 1 to 100
     * @param _maxWalletTokenPercentage set the percentage from 1% to 100%
     */
    function setMaxWalletTokens(uint256 _maxWalletTokenPercentage) public onlyOwner {
        if (_maxWalletTokenPercentage == 0 || _maxWalletTokenPercentage > 100)
            revert MemeTokenInvalidPercentage(_maxWalletTokenPercentage);

        _maxWalletTokens = (MAX_TOTAL_SUPPLY * _maxWalletTokenPercentage) / 100;
        emit MaxWalletAmountChanged(_maxWalletTokens);
    }
}
