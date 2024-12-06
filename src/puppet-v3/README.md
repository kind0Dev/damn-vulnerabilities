# Puppet V3

Bear or bull market, true DeFi devs keep building. Remember that lending pool you helped? A new version is out.

They’re now using Uniswap V3 as an oracle. That’s right, no longer using spot prices! This time the pool queries the time-weighted average price of the asset, with all the recommended libraries.

The Uniswap market has 100 WETH and 100 DVT in liquidity. The lending pool has a million DVT tokens.

Starting with 1 ETH and some DVT, you must save all from the vulnerable lending pool. Don't forget to send them to the designated recovery account.

_NOTE: this challenge requires a valid RPC URL to fork mainnet state into your local environment._



The key vulnerability here lies in the oracle manipulation. Even though they've upgraded to using TWAP instead of spot price, there's still a potential attack vector:

- The TWAP period is only 10 minutes, which is relatively short
- there is enough DVT (110) to significantly impact the price in the Uniswap pool
- The lending pool uses the manipulated TWAP to calculate collateral requirements

Here's a attack strategy:

1. Sell a large amount of DVT for WETH to manipulate the TWAP
2. Wait for the TWAP to reflect the manipulated price
3. Use the artificially low DVT price to borrow the entire lending pool with minimal collateral
4. Send the drained tokens to the recovery address

Let's go through how this solution works:

1. First, we approve the Uniswap V3 Router to spend our DVT tokens. This is necessary for making the swap.

2. We set up the swap parameters to sell all our DVT (110 tokens) for WETH. By selling a large amount relative to the pool size (which only has 100 DVT), we'll significantly impact the price.

3. Execute the swap, which will drive down the price of DVT relative to WETH in the pool.

4. Wait for some seconds. This ensures the 10-minute TWAP fully reflects our manipulated price. Since DVT is now worth much less relative to WETH, the collateral requirement will be much lower.

5. Calculate how much WETH we need to deposit to borrow the entire lending pool balance. Due to our price manipulation, this will be much less than it should be.

6. Wrap enough ETH into WETH to cover our required deposit.

7. Approve the lending pool to use our WETH as collateral.

8. Borrow the entire balance of DVT tokens from the lending pool.

9. Transfer all borrowed tokens to the recovery address.
