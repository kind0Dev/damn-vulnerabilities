# Puppet V2

The developers of the [previous pool](https://damnvulnerabledefi.xyz/challenges/puppet/) seem to have learned the lesson. And released a new version.

Now they’re using a Uniswap v2 exchange as a price oracle, along with the recommended utility libraries. Shouldn't that be enough?

You start with 20 ETH and 10000 DVT tokens in balance. The pool has a million DVT tokens in balance at risk!

Save all funds from the pool, depositing them into the designated recovery account.




The vulnerability lies in manipulating the Uniswap V2 price oracle used by the lending pool.

The vulnerability in the PuppetV2Pool challenge stems from the way the contract determines the quotation of the DamnValuableToken (DVT) token. It relies on a function called _getOracleQuote, which calculates the deposit quotation using the balance of the uniswapV2 pair contract’s reserves by uniswapV2Library function quote:.

Here's the solution:

Uniswap liquidity pools, especially those with low liquidity, are vulnerable to manipulation. In the PuppetV2Pool challenge, the balance of the liquidity pool is crucial in determining the token’s price. An attacker can exploit this by manipulating the pool’s balance to distort the perceived value of the DVT token.

Here’s a concise breakdown:

Token Swap: The attacker swaps a large amount of DVT tokens for ETH using Uniswap, dramatically increasing the DVT supply in the pool and crashing its price.
Price Manipulation: This action causes the PuppetV2Pool contract to perceive DVT as nearly worthless when it calls the quote function.
Minimal Collateral Deposit: Due to the artificially lowered DVT price, the attacker can now borrow all DVT tokens from PuppetV2Pool with minimal ETH collatera
You can clearly notice drastic decrease of depositRequired before(300_000 Eth) and after the swap(29.49 Eth) in following numbers.

After the swap, user has more Eth balance than depositRequired to borrow whole PuppetV2pool token balance, and that’s it!

So, we’ll simply borrow all, and will transfer to recovery address.