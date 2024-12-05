// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StakingVault} from './StakingVault.sol';

contract RewardContract {
    IERC20 public immutable rewardToken; // 1sDAI
    address public immutable vault;      // Address of the Vault

    uint256 public epochDuration = 14 days;
    uint256 public lastEpochStart;
    uint256 public rewardsPerEpoch;

    event RewardsDistributed(uint256 amount);

    constructor(IERC20 _rewardToken, address _vault, uint256 _initialRewards) {
        rewardToken = _rewardToken;
        vault = _vault;
        rewardsPerEpoch = _initialRewards;
        lastEpochStart = block.timestamp;
    }

    /// @dev Sets rewards for the next epoch
    function setNextEpochReward(uint256 amount) external {
        rewardsPerEpoch = amount;
    }

    /// @dev Distributes rewards for the current epoch
    function distributeRewards() external {
        // require(block.timestamp >= lastEpochStart + epochDuration, "Epoch not ended");

        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 amountToDistribute = balance < rewardsPerEpoch ? balance : rewardsPerEpoch;

        if (amountToDistribute > 0) {
            rewardToken.approve(vault, amountToDistribute);
            StakingVault(vault).depositRewards(amountToDistribute); // Calls the Vault
        }

        lastEpochStart = block.timestamp; // Start the next epoch
        emit RewardsDistributed(amountToDistribute);
    }
}
