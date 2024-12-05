# Puppet

There’s a lending pool where users can borrow Damn Valuable Tokens (DVTs). To do so, they first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.

There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.

Pass the challenge by saving all tokens from the lending pool, then depositing them into the designated recovery account. You start with 25 ETH and 1000 DVTs in balance.


The vulnerability lies in manipulating the Uniswap V1 price oracle used by the lending pool.

The lending pool calculates required ETH collateral based on the token price from Uniswap V1 pool's ETH/token ratio. By manipulating this ratio through a large token sale, we can dramatically reduce the collateral requirement, then borrow all tokens cheaply.

Here's the solution:



The attack works in these steps:

1. Sell all our 1000 DVT tokens to Uniswap, drastically reducing the token price
2. Calculate minimal ETH deposit needed to borrow all 100,000 tokens
3. Borrow all tokens directly to the recovery address

The price manipulation is possible because the pool uses Uniswap's balance ratio as an oracle without time-weighted average or manipulation resistance.
