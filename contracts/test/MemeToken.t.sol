// SPDX-License-Identifier: MIT
// solhint-disable one-contract-per-file
pragma solidity >=0.8.0;

import {stdStorage, StdStorage, Test} from "forge-std/Test.sol";

import {Utils} from "./utils/Utils.sol";

import {IMemeToken} from "../src/IMemeToken.sol";
import {MemeToken} from "../src/MemeToken.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract MemeTokenTest is Test {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;

    MemeToken internal memeToken;
    uint256 internal maxTransferAmount = 12e18;

    function setUp() public virtual {
        utils = new Utils();
        users = utils.createUsers(2);

        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");

        vm.label(address(this), "Owner");

        memeToken = new MemeToken(1);
    }

    function transferToken(address from, address to, uint256 transferAmount) public returns (bool) {
        vm.prank(from);
        return memeToken.transfer(to, transferAmount);
    }

    function transferTokenFrom(address from, address to, uint256 transferAmount) public returns (bool) {
        vm.prank(address(this));
        return memeToken.transferFrom(from, to, transferAmount);
    }

    function itTransfersAmountCorrectly(address from, address to, uint256 transferAmount) public {
        uint256 fromBalanceBefore = memeToken.balanceOf(from);
        bool success = transferToken(from, to, transferAmount);

        assertTrue(success);
        assertEqDecimal(memeToken.balanceOf(from), fromBalanceBefore - transferAmount, memeToken.decimals());
        assertEqDecimal(memeToken.balanceOf(to), transferAmount, memeToken.decimals());
    }

    function itTransfersFromAmountCorrectly(address from, address to, uint256 transferAmount) public {
        uint256 fromBalanceBefore = memeToken.balanceOf(from);
        bool success = transferTokenFrom(from, to, transferAmount);

        assertTrue(success);
        assertEqDecimal(memeToken.balanceOf(from), fromBalanceBefore - transferAmount, memeToken.decimals());
        assertEqDecimal(memeToken.balanceOf(to), transferAmount, memeToken.decimals());
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

contract WhenOwnerConfigureToken is MemeTokenTest {
    uint256 internal mintAmount = maxTransferAmount - 1e18;

    function testMaxWalletTokenSet() public view {
        assertEqDecimal(memeToken.maxWalletTokens(), 10_000_000 * 10 ** memeToken.decimals(), memeToken.decimals());
    }

    function testCannotConfigureLiquidityWalletZeroAddress() public {
        vm.prank(memeToken.owner());

        vm.expectRevert(abi.encodeWithSelector(IMemeToken.MemeTokenLiquidityPoolCantBeZero.selector));
        memeToken.setLiquidityPoolAddress(address(0));
    }

    function testCannotConfigureMaxWalletZero() public {
        vm.prank(memeToken.owner());
        vm.expectRevert(abi.encodeWithSelector(IMemeToken.MemeTokenInvalidPercentage.selector, 0));
        memeToken.setMaxWalletTokens(0);
    }

    function testCannotConfigureMaxWalletMoreThan100Percent() public {
        vm.prank(memeToken.owner());
        vm.expectRevert(abi.encodeWithSelector(IMemeToken.MemeTokenInvalidPercentage.selector, 101));
        memeToken.setMaxWalletTokens(101);
    }
}

contract WhenAliceHasSufficientFunds is MemeTokenTest {
    using stdStorage for StdStorage;
    uint256 internal mintAmount = maxTransferAmount;

    function setUp() public override {
        MemeTokenTest.setUp();

        transferToken(memeToken.owner(), alice, mintAmount);
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
            address(memeToken),
            abi.encodeWithSelector(memeToken.transfer.selector, bob, maxTransferAmount),
            abi.encode(false)
        );
        bool success = memeToken.transfer(bob, maxTransferAmount);
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

contract WhenAliceHasInsufficientFunds is MemeTokenTest {
    uint256 internal mintAmount = maxTransferAmount - 1e18;

    function setUp() public override {
        MemeTokenTest.setUp();

        transferToken(memeToken.owner(), alice, mintAmount);
    }

    function testCannotTransferMoreThanAvailable() public {
        itRevertsTransferInsufficientBalance({
            from: alice,
            to: bob,
            transferAmount: maxTransferAmount,
            fromBalance: memeToken.balanceOf(alice)
        });
    }

    function testCannotTransferToZero() public {
        itRevertsTransferInvalidReceiver({from: alice, to: address(0), transferAmount: mintAmount});
    }
}

contract WhenAliceTryToOverflowTransferTokens is MemeTokenTest {
    function setUp() public override {
        MemeTokenTest.setUp();
    }

    function itRevertsTransferMaxWalletTokens(address from, address to, uint256 transferAmount) public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IMemeToken.MemeTokenInvalidAmount.selector,
                memeToken.maxWalletTokens(),
                transferAmount,
                address(this),
                to
            )
        );

        transferToken(from, to, transferAmount);
    }

    function itRevertsTransferFromMaxWalletTokens(address from, address to, uint256 transferAmount) public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IMemeToken.MemeTokenInvalidAmount.selector,
                memeToken.maxWalletTokens(),
                transferAmount,
                address(this),
                to
            )
        );

        transferTokenFrom(from, to, transferAmount);
    }

    function testFuzz_CannotTransferMoreThanLimit(uint256 _transferAmount) public {
        _transferAmount = uint256(bound(_transferAmount, memeToken.maxWalletTokens() + 1, memeToken.totalSupply()));

        itRevertsTransferMaxWalletTokens({from: memeToken.owner(), to: alice, transferAmount: _transferAmount});
    }

    function testFuzz_CanTransferLessThabLimit(uint256 _transferAmount) public {
        _transferAmount = uint256(bound(_transferAmount, 1, memeToken.maxWalletTokens()));

        itTransfersAmountCorrectly(memeToken.owner(), alice, _transferAmount);
    }

    function testCannotTransferMoreThanLimitWhileBlocked() public {
        itRevertsTransferMaxWalletTokens({
            from: memeToken.owner(),
            to: alice,
            transferAmount: memeToken.totalSupply() - 1
        });
    }

    function testCanTransferMoreThanLimitWhenWalletAssigned() public {
        vm.prank(memeToken.owner());
        memeToken.setLiquidityPoolAddress(alice);

        itTransfersAmountCorrectly({from: memeToken.owner(), to: alice, transferAmount: memeToken.totalSupply() - 1});
    }

    function testCanTransferSetMoreLimit() public {
        vm.prank(memeToken.owner());
        memeToken.setMaxWalletTokens(10);

        itTransfersAmountCorrectly({from: memeToken.owner(), to: alice, transferAmount: memeToken.totalSupply() / 10});
    }
}

contract WhenOwnerHasSufficientAllowanceToTransfer is MemeTokenTest {
    using stdStorage for StdStorage;
    uint256 internal mintAmount = maxTransferAmount;

    function itRevertsTransferFromMaxWalletTokens(address from, address to, uint256 transferAmount) public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IMemeToken.MemeTokenInvalidAmount.selector,
                memeToken.maxWalletTokens(),
                transferAmount,
                address(this),
                to
            )
        );

        transferTokenFrom(from, to, transferAmount);
    }

    function setUp() public override {
        MemeTokenTest.setUp();

        transferToken(memeToken.owner(), alice, mintAmount);
    }

    function testTransferFromAllTokens() public {
        vm.prank(alice);
        memeToken.approve(address(this), maxTransferAmount);

        itTransfersFromAmountCorrectly(alice, bob, maxTransferAmount);
    }

    function testTransferFromHalfTokens() public {
        vm.prank(alice);
        memeToken.approve(address(this), maxTransferAmount / 2);

        itTransfersFromAmountCorrectly(alice, bob, maxTransferAmount / 2);
    }

    function testTransferFromOneToken() public {
        vm.prank(alice);
        memeToken.approve(address(this), 1);

        itTransfersFromAmountCorrectly(alice, bob, 1);
    }

    function testTransferFromWithFuzzing(uint64 transferAmount) public {
        vm.assume(transferAmount != 0);

        vm.prank(alice);
        memeToken.approve(address(this), transferAmount % maxTransferAmount);

        itTransfersFromAmountCorrectly(alice, bob, transferAmount % maxTransferAmount);
    }

    function testFuzz_CannotTransferFromMoreThanLimit(uint256 _transferAmount) public {
        _transferAmount = uint256(bound(_transferAmount, memeToken.maxWalletTokens() + 1, memeToken.totalSupply()));

        vm.prank(alice);
        memeToken.approve(address(this), _transferAmount);

        itRevertsTransferFromMaxWalletTokens(alice, bob, _transferAmount);
    }

    function testFuzz_CanTransferFromLessThanLimit(uint256 _transferAmount) public {
        _transferAmount = uint256(bound(_transferAmount, 1, memeToken.maxWalletTokens()));

        // Get the rest of the token so I can transfer
        transferToken(memeToken.owner(), alice, memeToken.maxWalletTokens() - mintAmount);

        vm.prank(alice);
        memeToken.approve(address(this), _transferAmount);

        itTransfersFromAmountCorrectly(alice, bob, _transferAmount);
    }
}
