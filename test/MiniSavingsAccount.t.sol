// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "./BaseTest.t.sol";
import "../src/MiniSavingsAccount.sol";
import "./mocks/Token.sol";

contract MiniSavingsAccountTest is BaseTest {
    MiniSavingsAccount public savingsAccount;
    Token public depositToken;
    Token public rewardToken;
    uint256 amount;

    function setUp() public override {
        super.setUp();
        depositToken = new Token("DepositToken", "DEP");
        rewardToken = new Token("RewardToken", "REW");
        savingsAccount = new MiniSavingsAccount(address(depositToken), address(rewardToken));

        amount = 1000;
        depositToken.mint(user1, amount);

        // provide liquidity for the rewards token from deployer to the savings account
        rewardToken.transfer(address(savingsAccount), 10000);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        depositToken.approve(address(savingsAccount), amount);
        savingsAccount.deposit(amount);

        assertEq(savingsAccount.balances(user1), amount);
    }

    function testEarned() public {
        vm.startPrank(user1);
        depositToken.approve(address(savingsAccount), amount);
        savingsAccount.deposit(amount);

        skip(10); // 10 seconds

        // should earn 1% per second - if deposited 1000, should earn 100 after 10 seconds
        assertEq(savingsAccount.getEarnings(user1), amount / 10);
    }

    function testClaim() public {
        vm.startPrank(user1);
        depositToken.approve(address(savingsAccount), amount);
        savingsAccount.deposit(amount);

        skip(10);
        savingsAccount.claimReward();

        // should earn 1% per second - if deposited 1000, should earn 100 after 10 seconds
        assertEq(rewardToken.balanceOf(user1), amount / 10);
    }
}
