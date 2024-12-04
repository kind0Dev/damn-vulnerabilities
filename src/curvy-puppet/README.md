# Curvy Puppet

There's a lending contract where anyone can borrow LP tokens from Curve's stETH/ETH pool. To do so, borrowers must first deposit enough Damn Valuable tokens (DVT) as collateral. If a position's borrowed value grows larger than the collateral's value, anyone can liquidate it by repaying the debt and seizing all collateral.

The lending contract integrates with [Permit2](https://github.com/Uniswap/permit2) to securely manage token approvals. It also uses a permissioned price oracle to fetch the current prices of ETH and DVT.

Alice, Bob and Charlie have opened positions in the lending contract. To be extra safe, they decided to really overcollateralize them.

But are they really safe? That's not what's claimed in the urgent bug report the devs received.

Before user funds are taken, close all positions and save all available collateral.

The devs have offered part of their treasury in case you need it for the operation: 200 WETH and a little over 6 LP tokens. Don't worry about profits, but don't use all their funds. Also, make sure to transfer any rescued assets to the treasury account.

_NOTE: this challenge requires a valid RPC URL to fork mainnet state into your local environment._


Let me analyze this challenge step by step.

1. The key vulnerability lies in the price calculation for LP tokens in the lending contract:
```solidity
function _getLPTokenPrice() private view returns (uint256) {
    return oracle.getPrice(curvePool.coins(0)).value.mulWadDown(curvePool.get_virtual_price());
}
```

2. The price depends on two factors:
   - The oracle price of ETH (coin0)
   - The virtual price from the Curve pool

3. The virtual price can be manipulated by executing large trades in the Curve pool. When we add a massive amount of ETH to one side of the pool, it significantly impacts the virtual price.

4. The exploit works by:
   - Taking a massive flashloan from any flashloan provider
   - Taking the treasury's LP tokens
   - exchanging massive ETH for sETH in the Curve pool
   - This manipulation makes pool inbalance
   - When pool is inbalance, the borrowed positions become unhealthy
   - We can then liquidate all positions, claiming the DVT collateral
   - Finally, we restore the treasury's funds sending back the remaing LPtokens and returning borrow assets

5. Key points about the implementation:
   - Uses Permit2 for token approvals
   - Ensures all rescued DVT goes to treasury
   - Returns remaining WETH and LP tokens to treasury
   - Leaves the treasury with more assets than before

This type of attack is a price oracle manipulation, specifically targeting how the lending contract calculates LP token prices. It shows why using manipulatable on-chain prices (like Curve's virtual price) in lending calculations can be dangerous.

Would you like me to explain any specific part in more detail?
