// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

interface IStakingVaultDeposit {
    event RewardsDeposited(uint256 amount);
    function depositRewards(uint256 amount) external;
}
