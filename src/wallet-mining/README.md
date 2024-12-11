# Wallet Mining

There’s a contract that incentivizes users to deploy Safe wallets, rewarding them with 1 DVT. It integrates with an upgradeable authorization mechanism, only allowing certain deployers (a.k.a. wards) to be paid for specific deployments.

The deployer contract only works with a Safe factory and copy set during deployment. It looks like the [Safe singleton factory](https://github.com/safe-global/safe-singleton-factory) is already deployed.

The team transferred 20 million DVT tokens to a user at `0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b`, where her plain 1-of-1 Safe was supposed to land. But they lost the nonce they should use for deployment.

To make matters worse, there's been rumours of a vulnerability in the system. The team's freaked out. Nobody knows what to do, let alone the user. She granted you access to her private key.

You must save all funds before it's too late!

Recover all tokens from the wallet deployer contract and send them to the corresponding ward. Also save and return all user's funds.

In a single transaction.




Let me break down the problem and solution in a much more detailed way.

**The Problem**:
1. There's a user who has 20M tokens at address `0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b`
2. This address is supposed to be a Gnosis Safe wallet, but it hasn't been deployed yet
3. We have access to the user's private key
4. There's a WalletDeployer contract that:
   - Gives rewards (1 DVT token) for deploying wallets
   - Has authorization controls for who can deploy where

**The Challenge**:
- We need to recover all the tokens from both the user's address AND the wallet deployer
- It must be done in a single transaction
- We must send the reward tokens to the ward address

**Key Concepts to Understand**:

1. **CREATE2 Predictability**:
```solidity
while (!flag) {
    address target = vm.computeCreate2Address(
        keccak256(abi.encodePacked(keccak256(initializer), nonce)),
        keccak256(abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(singletonCopy))))),
        address(proxyFactory)
    );
    if (target == USER_DEPOSIT_ADDRESS) {
        flag = true;
        break;
    }
    nonce++;
}
```
- CREATE2 allows us to predict the address where a contract will be deployed
- The address depends on:
  - The deploying factory's address
  - The contract's creation code
  - A salt (in this case, derived from the initializer and nonce)
- By iterating through nonces, we can find one that gives us our target address

2. **Safe Wallet Setup**:
```solidity
address[] memory _owners = new address[](1);
_owners[0] = user;
bytes memory initializer =
    abi.encodeCall(Safe.setup, (_owners, 1, address(0), "", address(0), address(0), 0, payable(0)));
```
- This creates initialization data for a 1-of-1 Safe wallet
- The user will be the only owner
- Threshold of 1 means only one signature needed

- EIP-712 is a standard for signing structured data
- For Safe transactions, we need to:
  1. Hash the transaction data with a type hash
  2. Create a domain separator (unique to the chain and Safe address)
  3. Combine these with the EIP-712 prefix (0x1901)
  4. Sign the resulting hash

4. **Pre-signing the Transaction**:
```solidity
(uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, txHash);
signatures = abi.encodePacked(r, s, v);
```
- We sign the transaction BEFORE the Safe is deployed
- This works because we can predict:
  - The exact address where the Safe will be deployed
  - The exact format of the transaction data
  - The domain separator that will be used

5. **The Complete Attack Flow**:
```plaintext
1. Calculate the nonce needed to deploy to 0x8be6...2b
2. Prepare a Safe transaction to transfer the 20M tokens
3. Pre-sign this transaction with the user's key
4. Deploy the Safe to the exact address using the calculated nonce
5. Immediately execute the pre-signed transaction
6. Send the reward tokens to the ward
```

**Why This Is Possible**:
1. CREATE2 makes contract addresses predictable
2. Safe uses EIP-712 signing which only depends on known values
3. We have the user's private key
4. WalletDeployer rewards us for the deployment

**The Main Exploit**:
The key insight is that we can:
1. Force a Safe deployment to an address that already has tokens
2. Pre-sign a transaction to move those tokens
3. Execute everything in one transaction

This works because:
- The Safe deployment is deterministic (thanks to CREATE2)
- The signature validation only depends on predictable values
- We have all the necessary permissions (user's private key)


