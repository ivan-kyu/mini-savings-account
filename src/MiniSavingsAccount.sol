// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract MiniSavingsAccount is ReentrancyGuard {
    error Deposit__TransferFailed();
    error Withdraw__TransferFailed();
    error PositiveNumRequired();

    /**
     * @dev Version 1 of the contract uses 2 separate tokens for simplicity
     */
    IERC20 public depositToken;
    IERC20 public rewardToken;

    uint256 public constant INTEREST_RATE = 10; // In basis points: 1000 = 100%; 10 = 1%
    uint256 public totalSupply;
    uint256 public rewardForDepositSaved;
    uint256 public lastUpdateTime;

    /**
     * @dev Mapping from address to the amount the account has deposited
     */
    mapping(address account => uint256 amountDeposited) public balances;

    /**
     * @dev Mapping from address to the amount the account has been rewarded
     */
    mapping(address account => uint256 rewardsPaid) public accountRewardsPaid;

    /**
     * @dev Account to claimable rewards
     */
    mapping(address account => uint256 claimableRewards) public rewards;

    modifier positiveNum(uint256 amount) {
        if (amount == 0) revert PositiveNumRequired();
        _;
    }

    constructor(address _depositToken, address _rewardToken) {
        depositToken = IERC20(_depositToken);
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @dev User deposits tokens into the contract
     */
    function deposit(uint256 amount) external positiveNum(amount) nonReentrant {
        _updateReward(msg.sender);
        balances[msg.sender] += amount;
        totalSupply += amount;
        bool success = depositToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert Deposit__TransferFailed();
    }

    /**
     * @dev User withdraws his tokens from the contract
     */
    function withdraw(uint256 amount) external positiveNum(amount) nonReentrant {
        _updateReward(msg.sender);
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        // emit event
        bool success = depositToken.transfer(msg.sender, amount);
        if (!success) revert Withdraw__TransferFailed();
    }

    /**
     * @dev User claims their earned rewards from the contract
     */
    function claimReward() external nonReentrant {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        bool success = rewardToken.transfer(msg.sender, reward);
        if (!success) revert Deposit__TransferFailed();
    }

    /**
     * @dev Get the amount which the account has earned (minus pastRewards) on the basis of how long it's been since lastUpdateTime (last change in amount)
     */
    function getEarnings(address account) public view returns (uint256) {
        uint256 currentBalance = balances[account];
        uint256 amountPaid = accountRewardsPaid[account];
        uint256 currentRewardForDeposit = _rewardForDeposit();
        uint256 pastRewards = rewards[account];
        uint256 earnedRewards = ((currentBalance * (currentRewardForDeposit - amountPaid)) / 1e18) + pastRewards;

        return earnedRewards;
    }

    /**
     * @dev Update the reward for the account
     */
    function _updateReward(address account) private {
        rewardForDepositSaved = _rewardForDeposit();
        lastUpdateTime = block.timestamp;
        rewards[account] = getEarnings(account);
        accountRewardsPaid[account] = rewardForDepositSaved;
    }

    /**
     * @dev Get the amount of rewards the contract has accumulated on the basis of how long it's been since lastUpdateTime (last change in amount)
     */
    function _rewardForDeposit() private view returns (uint256) {
        if (totalSupply == 0) {
            return rewardForDepositSaved;
        } else {
            return rewardForDepositSaved + (((block.timestamp - lastUpdateTime) * INTEREST_RATE * 1e18) / totalSupply);
        }
    }
}
