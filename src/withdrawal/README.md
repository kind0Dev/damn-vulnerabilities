# Withdrawal

There's a token bridge to withdraw Damn Valuable Tokens from an L2 to L1. It has a million DVT tokens in balance.

The L1 side of the bridge allows anyone to finalize withdrawals, as long as the delay period has passed and they present a valid Merkle proof. The proof must correspond with the latest withdrawals' root set by the bridge owner.

You were given the event logs of 4 withdrawals initiated on L2 in a JSON file. They could be executed on L1 after the 7 days delay.

But there's one suspicious among them, isn't there? You may want to double-check, because all funds might be at risk. Luckily you are a bridge operator with special powers.

Protect the bridge by finalizing _all_ given withdrawals, preventing the suspicious one from executing, and somehow not draining all funds.



The idea is to:
1. Use our operator privilege to submit a protective withdrawal first without proof
2. Then process the other legitimate withdrawals
3. Let the malicious withdrawal fail due to overflow or underflow

Here's how this solution works:

1. First, we calculate how much we need to rescue:
   - Total legitimate withdrawals are 6000 DVT (1500 + 2000 + 2500)
   - Bridge has 1,000,000 DVT
   - We'll rescue 900,000 DVT, leaving exactly enough for legitimate withdrawals

2. We use our operator privilege to submit a protective withdrawal without proof:
   - This moves 900,000 DVT to a safe address
   - No proof needed because we're an operator
   - Uses a different nonce to avoid conflicts
   - Sets timestamp appropriately to pass the delay check

3. Then we process the four legitimate withdrawals:
   - Each with proper proofs
   - In the correct order by nonce
   - With their original parameters

4. Finally, the third tx process the malicious withdrawal:
   - It will be marked as finalized
   - Although we rescued 900,000 tokens beforehand, and the third request attempts to transfer 999,000 tokens (which will fail), this failure    does not trigger a status check, so the entire transaction won't be reverted.
   - But will fail due to panic: arithmetic underflow or overflow (0x11)
   - Can't be replayed later because it's marked as finalized

This approach:
- Protects the majority of the bridge's funds
- Allows legitimate withdrawals to proceed
- Prevents the malicious withdrawal from succeeding
- Satisfies all test conditions by finalizing all withdrawals

The key insight is using the operator privilege to submit a protective withdrawal first, effectively moving funds to safety while leaving just enough for legitimate transactions.
