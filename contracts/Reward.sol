// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStakingVaultDeposit} from "./IStakingVaultDeposit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardContract is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken; // 1sDAI
    IStakingVaultDeposit public immutable vault; // Address of the Vault

    uint256 public epochDuration = 14 days;
    uint256 public lastEpochStart;
    uint256 public rewardsPerEpoch;

    event RewardsDistributed(uint256 amount);
    event EpochDurationUpdated(uint256 newDuration);
    event RewardsPerEpochUpdated(uint256 newAmount);

    constructor(IERC20 _rewardToken, IStakingVaultDeposit _vault, uint256 _initialRewards) Ownable(msg.sender) {
        rewardToken = _rewardToken;
        vault = _vault;
        rewardsPerEpoch = _initialRewards;
        lastEpochStart = block.timestamp;
    }

    function setNextEpochReward(uint256 amount) external onlyOwner {
        rewardsPerEpoch = amount;
        emit RewardsPerEpochUpdated(amount);
    }

    function setEpochDuration(uint256 newEpochDuration) external onlyOwner {
        epochDuration = newEpochDuration;
        emit EpochDurationUpdated(newEpochDuration);
    }

    function withdrawAssets(address recipient, uint256 amount) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(amount <= balance, "Insufficient contract balance");
        SafeERC20.safeTransfer(rewardToken, recipient, amount);
    }

    /// @dev Distributes rewards for the current epoch
    function distributeRewards() external {
        require(block.timestamp >= lastEpochStart + epochDuration, "Epoch not ended");

        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 amountToDistribute = balance >= rewardsPerEpoch ? rewardsPerEpoch : balance;

        require(amountToDistribute > 0, "No rewards available for distribution");

        rewardToken.approve(address(vault), 0); // Reset allowance
        rewardToken.approve(address(vault), amountToDistribute);
        vault.depositRewards(amountToDistribute);

        lastEpochStart = block.timestamp; // Start the next epoch
        emit RewardsDistributed(amountToDistribute);
    }

    function timeUntilNextEpoch() external view returns (uint256) {
        if (block.timestamp >= lastEpochStart + epochDuration) {
            return 0;
        }
        return (lastEpochStart + epochDuration) - block.timestamp;
    }
}
