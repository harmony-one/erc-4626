// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@contracts/Token.sol";
import { StakingVaultV2 } from "@contracts/StakingVaultV2.sol";
import "@contracts/Reward.sol";

contract DeployScriptTest is Test {
    Token token;
    StakingVaultV2 vault;
    RewardContract rewardContract;

    address deployer;
    address User1 = address(0x1235);
    address User2 = address(0x1236);
    address User3 = address(0x1237);
    address User4 = address(0x1238);
    address FeeRecepient = address(0x1239);

    function setUp() public {
        deployer = address(this);

        vm.deal(User1, 1000 ether);
        vm.deal(User2, 1000 ether);
        vm.deal(User3, 1000 ether);
        vm.deal(User4, 1000 ether);

        // Deploy Token
        token = new Token();
        token.initialize("1sDAI", "1sDAI");

        // Deploy StakingVaultV2
        vault = new StakingVaultV2(token, deployer);

        vault.setFeeBps(100); // 1% fee in basis points
        vault.setFeeRecipient(FeeRecepient);

        // Deploy RewardContract
        rewardContract = new RewardContract(token, vault, 3000 ether);

        // Mint tokens to deployer
        uint256 mintAmount = 1_000_000_000 ether; // 1 billion 1sDAI
        token.mint(deployer, mintAmount);

        token.mint(address(User1), 100 ether);
        token.mint(address(User2), 100 ether);
        token.mint(address(User3), 100 ether);
        token.mint(address(User4), 100 ether);

        token.mint(address(rewardContract), 10000 ether);
    }
/*
    function testWithdraw() public {
        uint256 depositAmount = 100 ether;
        uint256 balanceMinusFee = 99009900990099009900;

        vm.startPrank(User1);   
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User1);
        assertEq(token.balanceOf(User1), 0, 'User1 balance after deposit');
        assertEq(vault.balanceOf(User1), 99009900990099009900, 'User1 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 1 ether, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User2);   
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User2);
        assertEq(token.balanceOf(User2), 0, 'User2 balance after deposit');
        assertEq(vault.balanceOf(User2), 99 ether, 'User2 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 2 ether, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User3);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User3);
        assertEq(token.balanceOf(User3), 0, 'User2 balance after deposit');
        assertEq(vault.balanceOf(User3), 99 ether, 'User2 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 3 ether, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User1);   
        vault.withdraw(vault.balanceOf(User1), User1, User1);
        assertEq(token.balanceOf(User1), 98.01 ether, 'Final User1 balance');
        vm.stopPrank();

        vm.startPrank(User2);   
        vault.withdraw(vault.balanceOf(User2), User2, User2);
        assertEq(token.balanceOf(User2), 98.01 ether, 'Final User2 balance');
        vm.stopPrank();

        vm.startPrank(User3);   
        vault.withdraw(vault.balanceOf(User3), User3, User3);
        assertEq(token.balanceOf(User3), 98.01 ether, 'Final User3 balance');
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), 0, 'Final Vault balance');
        assertEq(token.balanceOf(FeeRecepient), 5.97 ether, 'Final FeeRecepient balance');
    }
*/
    function testRedeem() public {
        uint256 depositAmount = 100 ether;
        uint256 fee = 990099009900990100;
        uint256 depositMinusFee = depositAmount - fee;
        uint256 depositWillReturned = 98029604940692089009;

        vm.startPrank(User1);   
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User1);
        assertEq(token.balanceOf(User1), 0, 'User1 balance after deposit');
        assertEq(vault.balanceOf(User1), depositMinusFee, 'User1 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), fee, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User2);   
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User2);
        assertEq(token.balanceOf(User2), 0, 'User2 balance after deposit');
        assertEq(vault.balanceOf(User2), depositMinusFee, 'User2 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 2 * fee, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User3);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User3);
        assertEq(token.balanceOf(User3), 0, 'User2 balance after deposit');
        assertEq(vault.balanceOf(User3), depositMinusFee, 'User2 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 3 * fee, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User1);
        uint256 shares = vault.balanceOf(User1);
        vault.redeem(shares, User1, User1);
        assertEq(token.balanceOf(User1), depositWillReturned, 'Final User1 balance');
        vm.stopPrank();

        vm.startPrank(User2);  
        shares = vault.balanceOf(User2);
        vault.redeem(shares, User2, User2);
        assertEq(token.balanceOf(User2), depositWillReturned, 'Final User2 balance');
        vm.stopPrank();

        vm.startPrank(User3); 
        shares = vault.balanceOf(User3);
        vault.redeem(shares, User3, User3);
        assertEq(token.balanceOf(User3), depositWillReturned, 'Final User3 balance');
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), 0, 'Final Vault balance');
        assertEq(token.balanceOf(FeeRecepient), 5911185177923732973, 'Final FeeRecepient balance');
    }

    function testWithdrawWithRewards() public {
        uint256 depositAmount = 100 ether;
        uint256 fee = 990099009900990100; // ???
        uint256 depositMinusFee = depositAmount - fee;

        vm.startPrank(User1);   
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User1);
        assertEq(token.balanceOf(User1), 0, 'User1 balance after deposit');
        assertEq(vault.balanceOf(User1), depositMinusFee, 'User1 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), fee, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User2);   
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User2);
        assertEq(token.balanceOf(User2), 0, 'User2 balance after deposit');
        assertEq(vault.balanceOf(User2), depositMinusFee, 'User2 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 2 * fee, 'FeeRecepient balance deposit');
        vm.stopPrank();

        vm.startPrank(User3);
        token.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, User3);
        assertEq(token.balanceOf(User3), 0, 'User2 balance after deposit');
        assertEq(vault.balanceOf(User3), depositMinusFee, 'User2 balance on Vault after deposit');
        assertEq(token.balanceOf(FeeRecepient), 3 * fee, 'FeeRecepient balance deposit');
        vm.stopPrank();

        // send 3000 ethers to token Vault
        rewardContract.distributeRewards();

        vm.startPrank(User1);   
        vault.redeem(vault.balanceOf(User1), User1, User1);
        // ???
        assertEq(token.balanceOf(User1), 1088128614841682188015, 'Final User1 balance');
        vm.stopPrank();

        vm.startPrank(User2);   
        vault.redeem(vault.balanceOf(User2), User2, User2);
        // ???
        assertEq(token.balanceOf(User2), 1088128614841682188015, 'Final User2 balance');
        vm.stopPrank();

        vm.startPrank(User3);   
        vault.redeem(vault.balanceOf(User3), User3, User3);
        // ???
        assertEq(token.balanceOf(User3), 1088128614841682188016, 'Final User3 balance');
        vm.stopPrank();

        // ???
        assertEq(token.balanceOf(address(vault)), 11, 'Final Vault balance');
        // assertEq(token.balanceOf(FeeRecepient), 5.97 ether, 'Final FeeRecepient balance');
    }
}
