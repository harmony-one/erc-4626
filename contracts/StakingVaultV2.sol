// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IStakingVaultDeposit} from "./IStakingVaultDeposit.sol";

contract StakingVaultV2 is ERC4626, Ownable, IStakingVaultDeposit {
    using Math for uint256;

    uint256 public fee_bps = 10; // 0.1% fee in basis points
    address public feeRecipient;         // Wallet to receive fees

    uint256 private constant _BASIS_POINT_SCALE = 1e4;

    constructor(IERC20 asset, address _feeRecipient) Ownable(msg.sender)
    ERC20("boostDAI vault share token", "boostDAI")
    ERC4626(asset)
    {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = _feeRecipient;
    }

    // === Overrides ===

    /// @dev Preview taking an entry fee on deposit. See {IERC4626-previewDeposit}.
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee = _feeOnTotal(assets, _entryFeeBasisPoints());
        return super.previewDeposit(assets - fee);
    }

    /// @dev Preview adding an entry fee on mint. See {IERC4626-previewMint}.
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewMint(shares);
        return assets + _feeOnRaw(assets, _entryFeeBasisPoints());
    }

    /// @dev Preview adding an exit fee on withdraw. See {IERC4626-previewWithdraw}.
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee = _feeOnRaw(assets, _exitFeeBasisPoints());
        return super.previewWithdraw(assets + fee);
    }

    /// @dev Preview taking an exit fee on redeem. See {IERC4626-previewRedeem}.
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewRedeem(shares);
        return assets - _feeOnTotal(assets, _exitFeeBasisPoints());
    }

    /// @dev Send entry fee to {_entryFeeRecipient}. See {IERC4626-_deposit}.
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        uint256 fee = _feeOnTotal(assets, _entryFeeBasisPoints());
        address recipient = _entryFeeRecipient();

        super._deposit(caller, receiver, assets, shares);

        if (fee > 0 && recipient != address(this)) {
            SafeERC20.safeTransfer(IERC20(asset()), recipient, fee);
        }
    }

    /// @dev Send exit fee to {_exitFeeRecipient}. See {IERC4626-_deposit}.
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        uint256 fee = _feeOnRaw(assets, _exitFeeBasisPoints());
        address recipient = _exitFeeRecipient();

        super._withdraw(caller, receiver, owner, assets, shares);

        if (fee > 0 && recipient != address(this)) {
            SafeERC20.safeTransfer(IERC20(asset()), recipient, fee);
        }
    }

    // === Fee configuration ===

    function _entryFeeBasisPoints() internal view virtual returns (uint256) {
        return fee_bps; // replace with e.g. 100 for 1%
    }

    function _exitFeeBasisPoints() internal view virtual returns (uint256) {
        return fee_bps; // replace with e.g. 100 for 1%
    }

    function _entryFeeRecipient() internal view virtual returns (address) {
        return feeRecipient; // replace with e.g. a treasury address
    }

    function _exitFeeRecipient() internal view virtual returns (address) {
        return feeRecipient; // replace with e.g. a treasury address
    }

    // === Fee operations ===

    /// @dev Calculates the fees that should be added to an amount `assets` that does not already include fees.
    /// Used in {IERC4626-mint} and {IERC4626-withdraw} operations.
    function _feeOnRaw(uint256 assets, uint256 feeBasisPoints) private pure returns (uint256) {
        return assets.mulDiv(feeBasisPoints, _BASIS_POINT_SCALE - feeBasisPoints, Math.Rounding.Ceil);
    }

    /// @dev Calculates the fee part of an amount `assets` that already includes fees.
    /// Used in {IERC4626-deposit} and {IERC4626-redeem} operations.
    function _feeOnTotal(uint256 assets, uint256 feeBasisPoints) private pure returns (uint256) {
        return assets.mulDiv(feeBasisPoints, _BASIS_POINT_SCALE, Math.Rounding.Ceil);
    }

    /// @dev Update fee recipient address
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = newRecipient;
    }

    /// @dev Update fee
    function setFeeBps(uint256 new_fee_bps) external onlyOwner {
        fee_bps = new_fee_bps;
    }

    /// @dev Function for Reward Contract to deposit rewards
    function depositRewards(uint256 amount) external {
        IERC20(asset()).transferFrom(msg.sender, address(this), amount);
        emit RewardsDeposited(amount);
    }
}