# Naive Receiver

There’s a pool with 1000 WETH in balance offering flash loans. It has a fixed fee of 1 WETH. The pool supports meta-transactions by integrating with a permissionless forwarder contract. 

A user deployed a sample contract with 10 WETH in balance. Looks like it can execute flash loans of WETH.

All funds are at risk! Rescue all WETH from the user and the pool, and deposit it into the designated recovery account.




The exploit strategy:

1. First part drain the receiver using flash loan fees through by borrowing 10 times
2. For the pool funds:
   - We need to use the BasicForwarder to impersonate someone who has deposits (like the deployer)
   - Create a meta-transaction request for withdrawal
   - Sign it appropriately
   - Execute through the forwarder

However, if you notice there are potential issues with this approach too:
1. We need the deployer's signature/private key
2. The deployer has the deposits, but we might not have access to impersonate them

The key to understanding this solution lies in how function calls are encoded in Ethereum and how `abi.encodePacked` works with them.

When `abi.encodeCall` encodes the withdraw function, it creates:
1. First 4 bytes: function selector (withdraw's signature hash)
2. Following bytes: encoded arguments (amount and recovery address)

When this encoded call data is passed through `functionDelegateCall` in the Multicall contract, the pool contract receives this call data.

Now, when `_msgSender()` runs in the pool contract during withdrawal, it:
1. Sees the forwarder as `msg.sender`
2. Checks if data length ≥ 20 bytes (true)
3. Takes last 20 bytes of the call data
4. Those 20 bytes are the deployer address we appended

By appending the deployer address with `abi.encodePacked`, we ensure it appears at the end of the call data, making `_msgSender()` return the deployer's address instead of the actual caller.

This works because `abi.encodePacked` concatenates raw bytes without padding, placing the deployer address exactly where `_msgSender()` looks for it.

The behavior of `_msgSender()` in this case is determined by how Solidity handles calldata during delegate calls. Let's analyze it step by step:

When the delegate call executes:
- The original calldata from forwarder contains: [multicall function data][player address]
- The multicall function executes with: [withdraw function data][deployer address][player address]
- `_msgSender()` reads the last 20 bytes of the actual function call data, which contains our injected deployer address, not the player address appended by the forwarder

This happens because `delegatecall` maintains the original calldata context within the multicall execution, allowing us to control what `_msgSender()` reads.
