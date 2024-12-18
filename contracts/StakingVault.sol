// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingVault is ERC4626, Ownable {
    uint256 public constant FEE_BPS = 10; // 0.1% fee in basis points
    address public feeRecipient;         // Wallet to receive fees

    event RewardsDeposited(uint256 amount);
    event ExchangeRateUpdated(uint256 rewardsAdded);

    constructor(IERC20 asset, address _feeRecipient) Ownable(msg.sender)
        ERC20("Staking Vault Share", "SVS")
        ERC4626(asset)
    {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
    }

    /// @dev Override deposit to include a fee
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        require(assets > 0, "Assets must be greater than zero");

        // Calculate fee
        uint256 fee = (assets * FEE_BPS) / 10_000;
        uint256 netAssets = assets - fee;

        // Transfer fee to feeRecipient
        IERC20(asset()).transferFrom(msg.sender, feeRecipient, fee);

        // Deposit net assets to vault and mint shares
        shares = super.deposit(netAssets, receiver);
    }

    /// @dev Override withdraw to include a fee
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        require(assets > 0, "Assets must be greater than zero");

        // Calculate fee
        uint256 fee = (assets * FEE_BPS) / 10_000;
        uint256 netAssets = assets - fee;

        // Transfer fee to feeRecipient
        IERC20(asset()).transfer(feeRecipient, fee);

        // Withdraw net assets from vault and burn shares
        shares = super.withdraw(netAssets, receiver, owner);
    }

    /// @dev Function to update the exchange rate after reward distribution
    function updateExchangeRate(uint256 rewardsAdded) external onlyOwner {
        require(rewardsAdded > 0, "Rewards must be greater than zero");
        IERC20(asset()).transferFrom(msg.sender, address(this), rewardsAdded);
        emit ExchangeRateUpdated(rewardsAdded);
    }

    /// @dev Update fee recipient address
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = newRecipient;
    }

    /// @dev Function for Reward Contract to deposit rewards
    function depositRewards(uint256 amount) external {
        IERC20(asset()).transferFrom(msg.sender, address(this), amount);
        emit RewardsDeposited(amount);
    }
}