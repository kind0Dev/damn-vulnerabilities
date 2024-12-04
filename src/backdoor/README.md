# Backdoor

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Safe wallets. When someone in the team deploys and registers a wallet, they earn 10 DVT tokens.

The registry tightly integrates with the legitimate Safe Proxy Factory. It includes strict safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Uncover the vulnerability in the registry, rescue all funds, and deposit them into the designated recovery account. In a single transaction.


 // * Most of the logic is placed in the Smart Contract to allow this to happen
    //  * in one transaction. But essentially it goes:
    //  * 
    //  * 1. Deploy malicious contract
    //  * 2. Generate the ABI to call the setupToken() function in the malicious contract
    //  * 3. exploit(): Call exploit with the above ABI and the list of users
    //  * 4. exploit(): Generate the ABI to setup the new Gnosis wallet with the ABI from step 2
    //  *                  such that the callback address and function is the wallet registry
    //  * 5. exploit(): Call the ProxyFactory contract with the ABI from step 4 and a few other bobs
    //  *              with a callback to the WalletRegistry proxyCreated() function.
    //  * 6. createProxyWithCallback(): Deploys the new Proxy and calls setup() on the proxy
    //  * 7. setup(): New proxy is setup and sets up the module calling back to the malicous contract
    //  *              however this time is a delegate call meaning it is executed in the context
    //  *              of the newly create proxy contract.
    //  * 8. setupToken(): [proxy context] Approve 10 ether to be spent by the malicious contract
    //  *                  of the proxies token funds
    //  * 9. proxyCreated(): Callback executed on the wallet registry and passes checks and transfers
    //  *                      10 ether to the newly created wallet
    //  * 10. exploit(): Transfer the 10 ether from the Gnosis wallet to the attacker address
    //  * 11. Repeat for each beneficiary from within the contract and hence 1 transaction.
    //  * Attact contract can be found in the attack-contracts/BackdoorAttack.sol
    //  * After which you just deploy the BackdoorAttack and transfer all the token to the recovery address
