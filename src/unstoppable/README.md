# Unstoppable

There's a tokenized vault with a million DVT tokens deposited. It’s offering flash loans for free, until the grace period ends.

To catch any bugs before going 100% permissionless, the developers decided to run a live beta in testnet. There's a monitoring contract to check liveness of the flashloan feature.

Starting with 10 DVT tokens in balance, show that it's possible to halt the vault. It must stop offering flash loans.



- Key vulnerability found:
- The vault validates that the converted shares match the total assets
- This check can be broken by directly transferring tokens to the vault without minting shares
- When users deposit properly through the ERC4626 deposit function, shares are minted keeping the ratio correct
- But if we transfer tokens directly using the underlying ERC20's transfer function, we break this ratio


Let me explain why this works:

1. The vault uses ERC4626 standard which maintains a ratio between shares and assets. When users deposit properly through the vault's deposit() function, they receive shares proportional to their deposit.

2. However, the vault's flashLoan() function has a strict check:
```solidity
if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance();
```

3. By transferring tokens directly to the vault (bypassing deposit()), we:
- Increase the vault's token balance (totalAssets)
- Don't increase the totalSupply of shares
- This breaks the expected 1:1 ratio between shares and assets

4. This causes the InvalidBalance check to fail permanently, as:
- totalAssets() returns the actual token balance (now higher)
- convertToShares(totalSupply) converts the unchanged share supply
- These values no longer match
- The flashLoan() function will always revert

5. When the monitor contract tries to check the flash loan functionality, it will fail, causing it to:
- Emit FlashLoanStatus(false)
- Pause the vault
- Transfer ownership to the deployer

This solution demonstrates how seemingly innocent design assumptions (that all tokens will come through proper deposits) can lead to vulnerabilities in DeFi protocols.

