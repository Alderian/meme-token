// SPDX-License-Identifier: MIT
// solhint-disable one-contract-per-file
pragma solidity >=0.8.0;

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";

import {Utils} from "./utils/Utils.sol";
import {IMemeToken} from "../src/IMeme.sol";
import {MemeToken} from "../src/Meme.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract BaseSetup is MemeToken, Test {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;

    uint256 blockedTime = 1 hours;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(2);

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");

        vm.label(this.owner(), "Owner");
    }

    constructor() MemeToken(block.timestamp + blockedTime, 1) {}
}

contract WhenTransferringTokens is BaseSetup {
    uint256 internal maxTransferAmount = 12e18;

    function setUp() public virtual override {
        BaseSetup.setUp();
    }

    function transferToken(address from, address to, uint256 transferAmount) public returns (bool) {
        vm.prank(from);
        return this.transfer(to, transferAmount);
    }

    function itTransfersAmountCorrectly(address from, address to, uint256 transferAmount) public {
        uint256 fromBalanceBefore = balanceOf(from);
        bool success = transferToken(from, to, transferAmount);

        assertTrue(success);
        assertEqDecimal(balanceOf(from), fromBalanceBefore - transferAmount, decimals());
        assertEqDecimal(balanceOf(to), transferAmount, decimals());
    }

    function itRevertsTransferInsufficientBalance(
        address from,
        address to,
        uint256 transferAmount,
        uint256 fromBalance
    ) public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, from, fromBalance, transferAmount)
        );
        transferToken(from, to, transferAmount);
    }

    function itRevertsTransferInvalidReceiver(address from, address to, uint256 transferAmount) public {
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, 0));
        transferToken(from, to, transferAmount);
    }
}

contract WhenAliceHasSufficientFunds is WhenTransferringTokens {
    using stdStorage for StdStorage;
    uint256 internal mintAmount = maxTransferAmount;

    function setUp() public override {
        WhenTransferringTokens.setUp();

        _mint(alice, mintAmount);
    }

    function testTransferAllTokens() public {
        itTransfersAmountCorrectly(alice, bob, maxTransferAmount);
    }

    function testTransferHalfTokens() public {
        itTransfersAmountCorrectly(alice, bob, maxTransferAmount / 2);
    }

    function testTransferOneToken() public {
        itTransfersAmountCorrectly(alice, bob, 1);
    }

    function testTransferWithFuzzing(uint64 transferAmount) public {
        vm.assume(transferAmount != 0);
        itTransfersAmountCorrectly(alice, bob, transferAmount % maxTransferAmount);
    }

    function testTransferWithMockedCall() public {
        vm.prank(alice);
        vm.mockCall(
            address(this),
            abi.encodeWithSelector(this.transfer.selector, bob, maxTransferAmount),
            abi.encode(false)
        );
        bool success = this.transfer(bob, maxTransferAmount);
        assertTrue(!success);
        vm.clearMockedCalls();
    }

    // // example how to use https://github.com/foundry-rs/forge-std stdStorage
    // function testFindMapping() public {
    //     uint256 slot = stdstore.target(address(this)).sig(this.balanceOf.selector).with_key(alice).find();
    //     bytes32 data = vm.load(address(this), bytes32(slot));
    //     assertEqDecimal(uint256(data), mintAmount, decimals());
    // }
}

contract WhenAliceHasInsufficientFunds is WhenTransferringTokens {
    uint256 internal mintAmount = maxTransferAmount - 1e18;

    function setUp() public override {
        WhenTransferringTokens.setUp();

        _mint(alice, mintAmount);
    }

    function testCannotTransferMoreThanAvailable() public {
        itRevertsTransferInsufficientBalance({
            from: alice,
            to: bob,
            transferAmount: maxTransferAmount,
            fromBalance: balanceOf(alice)
        });
    }

    function testCannotTransferToZero() public {
        itRevertsTransferInvalidReceiver({from: alice, to: address(0), transferAmount: mintAmount});
    }
}

contract WhenAliceTryToOverflowTransferTokens is WhenTransferringTokens {
    function setUp() public override {
        WhenTransferringTokens.setUp();
    }

    function itRevertsTransferMaxWalletTokens(address from, address to, uint256 transferAmount) public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IMemeToken.MemeTokenInvalidAmount.selector,
                this.MAX_WALLET_TOKENS(),
                transferAmount,
                this.TIMESTAMP_DISABLE_MAX_WALLET_TOKENS(),
                block.timestamp
            )
        );

        transferToken(from, to, transferAmount);
    }

    function testCannotTransferMoreThanLimit() public {
        itRevertsTransferMaxWalletTokens({from: this.owner(), to: alice, transferAmount: this.totalSupply() - 1});
    }

    function testCannotTransferMoreThanLimitAtBlockTimeLimit() public {
        // Move just after blocked time
        skip(blockedTime);

        itRevertsTransferMaxWalletTokens({from: this.owner(), to: alice, transferAmount: this.totalSupply() - 1});
    }

    function testCanTransferMoreThanLimitWhenTimePassed() public {
        // Move just after blocked time
        skip(blockedTime + 1 seconds);

        itTransfersAmountCorrectly({from: this.owner(), to: alice, transferAmount: this.totalSupply() - 1});
    }
}
