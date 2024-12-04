# Free Rider

A new marketplace of Damn Valuable NFTs has been released! There’s been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

A critical vulnerability has been reported, claiming that all tokens can be taken. Yet the developers don't know how to save them!

They’re offering a bounty of 45 ETH for whoever is willing to take the NFTs out and send them their way. The recovery process is managed by a dedicated smart contract.

You’ve agreed to help. Although, you only have 0.1 ETH in balance. The devs just won’t reply to your messages asking for more.

If only you could get free ETH, at least for an instant.



Let's analyze the key vulnerabilities in this NFT marketplace:


1. In `_buyOne()`, there's a critical payment bug:
```solidity
_token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);
payable(_token.ownerOf(tokenId)).sendValue(priceToPay);
```
The payment occurs AFTER the NFT transfer, meaning `ownerOf(tokenId)` returns the new owner (buyer). The buyer gets paid instead of the seller.

2. Flash loans from Uniswap V2 can provide the required ETH temporarily.

Here's how to exploit this:

The exploit:
1. Uses flash swap to borrow 15 ETH worth of WETH
2. Buys all NFTs for 15 ETH total (due to payment bug)
3. Forwards NFTs to recovery manager
4. Repays flash loan using received ETH
5. Player collects 45 ETH bounty

The marketplace loses all NFTs while only paying 15 ETH due to the payment vulnerability.