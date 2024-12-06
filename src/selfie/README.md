# Selfie

A new lending pool has launched! It’s now offering flash loans of DVT tokens. It even includes a fancy governance mechanism to control it.

What could go wrong, right ?

You start with no DVT tokens in balance, and the pool has 1.5 million at risk.

Rescue all funds from the pool and deposit them into the designated recovery account.




Now, let’s discuss how we can exploit this setup to achieve our objective of acquiring all the DVT tokens.

We notice that the governance mechanism allows the execution of actions, including the emergencyExit function in the pool contract. However, the emergencyExit function can only be called by the governance contract itself.
We need to create an action in the governance in order to execute the emergencyExit function with our parameters.
In order to queueAction we need at least 50% of the DVT tokens supply, which we don't have.
We can utilize the flash loan function in the SelfiePool.sol contract to borrow a significant amount of DVT tokens without collateral which will be enough to queue actions. This is our entry point for the exploit.
