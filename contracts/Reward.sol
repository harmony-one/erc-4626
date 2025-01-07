// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StakingVault} from "./StakingVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardContract is Ownable {
    IERC20 public immutable rewardToken; // 1sDAI
    address public immutable vault; // Address of the Vault

    uint256 public epochDuration = 14 days;
    uint256 public lastEpochStart;
    uint256 public rewardsPerEpoch;

    event RewardsDistributed(uint256 amount);

    constructor(IERC20 _rewardToken, address _vault, uint256 _initialRewards) Ownable(msg.sender) {
        rewardToken = _rewardToken;
        vault = _vault;
        rewardsPerEpoch = _initialRewards;
        lastEpochStart = block.timestamp;
    }

    function setNextEpochReward(uint256 amount) external onlyOwner {
        rewardsPerEpoch = amount;
    }

    function setEpochDuration(uint256 newEpochDuration) external onlyOwner {
        epochDuration = newEpochDuration;
    }

    /// @dev Distributes rewards for the current epoch
    function distributeRewards() external {
        require(block.timestamp >= lastEpochStart + epochDuration, "Epoch not ended");

        uint256 balance = rewardToken.balanceOf(address(this));

        require(balance > rewardsPerEpoch, "balance not enough");

        rewardToken.approve(vault, rewardsPerEpoch);
        StakingVault(vault).depositRewards(rewardsPerEpoch); // Calls the Vault

        lastEpochStart = block.timestamp; // Start the next epoch
        emit RewardsDistributed(rewardsPerEpoch);
    }
}
