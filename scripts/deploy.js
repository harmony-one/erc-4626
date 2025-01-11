const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners()

    // ----------- Deploy the Token (1sDAI) -----------
    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy(); // Name, symbol, decimals
    await token.deployed();
    await token.initialize('1sDAI', '1sDAI');
    console.log(`1sDAI token deployed at address: ${token.address}`);

    // ----------- Deploy the StakingVault -----------
    const feeRecipient = deployer.address; // Specify the fee recipient address
    const StakingVault = await ethers.getContractFactory("StakingVaultV2");
    const vault = await StakingVault.deploy(token.address, feeRecipient);
    await vault.deployed();
    console.log(`StakingVault deployed at address: ${vault.address}`);

    // ----------- Deploy RewardContract -----------
    console.log("Deploying RewardContract...");
    const initialRewards = ethers.utils.parseUnits("100", 18); // 100 1sDAI for rewards
    const RewardContract = await ethers.getContractFactory("RewardContract");
    const rewardContract = await RewardContract.deploy(token.address, vault.address, initialRewards);
    await rewardContract.deployed();
    console.log(`RewardContract deployed at: ${rewardContract.address}`);

    const epochDuration = 60 * 60; // 1h in seconds
    await rewardContract.setEpochDuration(epochDuration);

     // ----------- Example Usage -----------

    // Setup signer
    console.log(`Using deployer account: ${deployer.address}`);

    const mintAmount = ethers.utils.parseUnits("1000000000", 18);   
    let tx = await token.mint(deployer.address, mintAmount);
    await tx.wait(); 

     // ----------- Approve and Fund RewardContract -----------
     console.log("Funding RewardContract with rewards...");
     const rewardAmount = ethers.utils.parseUnits("500", 18); // 500 1sDAI for rewards

     tx = await token.approve(rewardContract.address, rewardAmount);
     await tx.wait();
     tx = await token.transfer(rewardContract.address, rewardAmount);
     await tx.wait();
     console.log("RewardContract funded with rewards.");
 
     // ----------- Set Rewards for Next Epoch -----------
     const nextEpochRewards = ethers.utils.parseUnits("100", 18); // 100 1sDAI for the next epoch
     console.log("Setting rewards for the next epoch...");
     tx = await rewardContract.setNextEpochReward(nextEpochRewards);
     await tx.wait();
     console.log(`Rewards for next epoch set to: ${ethers.utils.formatUnits(nextEpochRewards, 18)} 1sDAI.`);
 
     // ----------- Approve and Deposit into StakingVault -----------
     console.log("Approving tokens for deposit into StakingVault...");
     const depositAmount = ethers.utils.parseUnits("100", 18); // 100 1sDAI
     tx = await token.approve(vault.address, depositAmount);
     await tx.wait();
     console.log("Tokens approved for deposit.");
 
     console.log("Depositing tokens into StakingVault...");
     tx = await vault.deposit(depositAmount, deployer.address);
     await tx.wait();
     console.log("Deposit completed.");
 
     // ----------- Advance Epoch and Distribute Rewards -----------
     console.log("Advancing epoch and distributing rewards...");
     tx = await rewardContract.distributeRewards();
     await tx.wait();
     console.log("Rewards distributed.");
 
     // ----------- Check Share Token Balance and Withdraw -----------
     console.log("Checking share token balance...");
     const shares = await vault.convertToShares(depositAmount);
     console.log(`Received ${ethers.utils.formatUnits(shares, 18)} share tokens.`);
 
     const withdrawAmount = ethers.utils.parseUnits("50", 18); // 50 1sDAI
     console.log("Withdrawing tokens from StakingVault...");
     tx = await vault.withdraw(withdrawAmount, deployer.address, deployer.address);
     await tx.wait();
     console.log("Withdrawal completed.");
}

main().catch((error) => {
    console.error("Error during contract deployment:", error);
    process.exitCode = 1;
});
