# Shards

The Shards NFT marketplace is a permissionless smart contract enabling holders of Damn Valuable NFTs to sell them at any price (expressed in USDC).

These NFTs could be so damn valuable that sellers can offer them in smaller fractions ("shards"). Buyers can buy these shards, represented by an ERC1155 token. The marketplace only pays the seller once the whole NFT is sold.

The marketplace charges sellers a 1% fee in Damn Valuable Tokens (DVT). These can be stored in a secure on-chain vault, which in turn integrates with a DVT staking system.

Somebody is selling one NFT for... wow, a million USDC?

You better dig into that marketplace before the degens find out.

You start with no DVTs. Rescue as much funds as you can in a single transaction, and deposit the assets into the designated recovery account.




Key Vulnerability: Precision Loss in Price Calculation
The core vulnerability lies in the interaction between two mathematical operations:

1. In `fill()`:
```solidity
want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)
```

2. In `_toDVT()`:
```solidity
return _value.mulDivDown(_rate, 1e6);
```

Here's why this creates an exploitable condition:

1. Price Calculation Breakdown:
- The offer price is 1,000,000e6 (USDC)
- Total shards is 10,000,000e18
- Current rate is 75e15 (DVT/USDC)

2. When we request 100 shards:
```
Step 1: _toDVT(1_000_000e6, 75e15)
= (1_000_000e6 * 75e15) / 1e6 
= 75e21

Step 2: want * _toDVT(price, rate) / totalShards
= 100 * 75e21 / 10_000_000e18
= 7500e21 / 10_000_000e18
≈ 0 (due to precision loss)
```

3. Exploitation Process:
```solidity
// Request small enough number of shards (<=133) 
marketplace.fill(offerId, 100);  // Costs 0 DVT due to rounding
marketplace.cancel(1, i);        // Get DVT refund
```

The exploit works because:
- When requesting ≤133 shards, the division results in such a small number that it rounds to 0
- The marketplace still records the purchase
- When cancelling, we receive DVT tokens back even though we paid nothing
- By repeating this 10,001 times, we can drain significant DVT from the contract

Key Points:
1. No initial DVT needed to execute the attack
2. Each iteration is profitable due to zero cost entry
3. The number 133 is the maximum shards that results in zero cost
4. The loop count (10,001) is calibrated to extract maximum value

This demonstrates a classic precision loss vulnerability where seemingly innocent mathematical operations can be exploited when the numbers involved are carefully chosen to trigger rounding to zero.

