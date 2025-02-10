// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IStakingVaultDeposit} from "./IStakingVaultDeposit.sol";

contract RewardContract is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public immutable rewardToken;
    IStakingVaultDeposit public immutable vault;

    uint256 public epochDuration = 14 days;
    uint256 public lastEpochStart;
    uint256 public rewardsPerEpoch;

    event RewardsDistributed(uint256 amount);
    event EpochDurationUpdated(uint256 newDuration);
    event RewardsPerEpochUpdated(uint256 newAmount);

    constructor(IERC20 _rewardToken, IStakingVaultDeposit _vault, uint256 _initialRewards, address admin) {
        rewardToken = _rewardToken;
        vault = _vault;
        rewardsPerEpoch = _initialRewards;
        lastEpochStart = block.timestamp;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function setNextEpochReward(uint256 amount) external onlyRole(MANAGER_ROLE) {
        rewardsPerEpoch = amount;
        emit RewardsPerEpochUpdated(amount);
    }

    function setEpochDuration(uint256 newEpochDuration) external onlyRole(MANAGER_ROLE) {
        epochDuration = newEpochDuration;
        emit EpochDurationUpdated(newEpochDuration);
    }

    function withdrawAssets(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(amount <= balance, "Insufficient contract balance");
        SafeERC20.safeTransfer(rewardToken, recipient, amount);
    }

    function distributeRewards() external {
        require(block.timestamp >= lastEpochStart + epochDuration, "Epoch not ended");

        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 amountToDistribute = balance >= rewardsPerEpoch ? rewardsPerEpoch : balance;

        require(amountToDistribute > 0, "No rewards available for distribution");

        rewardToken.approve(address(vault), 0);
        rewardToken.approve(address(vault), amountToDistribute);
        vault.depositRewards(amountToDistribute);

        lastEpochStart = block.timestamp;
        emit RewardsDistributed(amountToDistribute);
    }

    function timeUntilNextEpoch() external view returns (uint256) {
        return block.timestamp >= lastEpochStart + epochDuration ? 0 : (lastEpochStart + epochDuration) - block.timestamp;
    }

    function grantManagerRole(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MANAGER_ROLE, manager);
    }

    function revokeManagerRole(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MANAGER_ROLE, manager);
    }
}