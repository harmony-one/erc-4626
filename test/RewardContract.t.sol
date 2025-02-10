// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import "@contracts/Reward.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MockVault is IStakingVaultDeposit {
    function depositRewards(uint256 amount) external override {}
}

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1e24);
    }
}

contract RewardContractTest is Test {
    RewardContract rewardContract;
    MockToken rewardToken;
    MockVault vault;
    address admin = address(0x1);
    address manager = address(0x2);
    address user = address(0x3);

    function setUp() public {
        rewardToken = new MockToken();
        vault = new MockVault();
        vm.prank(admin);
        rewardContract = new RewardContract(IERC20(address(rewardToken)), IStakingVaultDeposit(address(vault)), 1000, admin);
    }

    function testAdminCanGrantManagerRole() public {
        vm.prank(admin);
        rewardContract.grantManagerRole(manager);
        assertTrue(rewardContract.hasRole(rewardContract.MANAGER_ROLE(), manager));
    }

    function testManagerCanSetEpochReward() public {
        vm.prank(admin);
        rewardContract.grantManagerRole(manager);
        vm.prank(manager);
        rewardContract.setNextEpochReward(5000);
        assertEq(rewardContract.rewardsPerEpoch(), 5000);
    }

    function testManagerCanSetEpochDuration() public {
        vm.prank(admin);
        rewardContract.grantManagerRole(manager);
        vm.prank(manager);
        rewardContract.setEpochDuration(10 days);
        assertEq(rewardContract.epochDuration(), 10 days);
    }

    function testNonManagerCannotSetEpochReward() public {
        vm.prank(user);
        vm.expectRevert("AccessControlUnauthorizedAccount(0x0000000000000000000000000000000000000003, 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08)");
        rewardContract.setNextEpochReward(5000);
    }

    function testDistributeRewards() public {
        vm.prank(admin);
        rewardToken.transfer(address(rewardContract), 2000);
        vm.warp(block.timestamp + rewardContract.epochDuration());
        vm.prank(admin);
        rewardContract.distributeRewards();
        assertEq(rewardToken.balanceOf(address(vault)), 1000);
    }
}