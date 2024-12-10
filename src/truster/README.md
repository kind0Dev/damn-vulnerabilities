# Truster

More and more lending pools are offering flashloans. In this case, a new pool has launched that is offering flashloans of DVT tokens for free.

The pool holds 1 million DVT tokens. You have nothing.

To pass this challenge, rescue all funds in the pool executing a single transaction. Deposit the funds into the designated recovery account.


This is a vulnerable flash loan contract where the key issue lies in the ability to execute arbitrary function calls during the flash loan.
The vulnerability lies in the `functionCall` feature of the flash loan contract that allows calling arbitrary functions on any target.

1. The exploit works in these steps:
   - We create an exploit contract that will execute in a single transaction
   - We don't actually need to borrow any tokens (amount = 0)
   - We use the `functionCall` to call `approve` on the token contract
   - This approves our exploit contract to spend the pool's tokens
   - We then use `transferFrom` to move all tokens to the recovery address

2. Key vulnerabilities:
   - The pool allows arbitrary function calls to any target
   - There's no validation on what functions can be called
   - The balance check only ensures the pool's balance isn't less than before

3. This works because:
   - The flash loan's balance check passes (we didn't borrow anything)
   - We gain approval to spend the pool's tokens through the arbitrary call
   - We can then transfer all tokens in the same transaction



