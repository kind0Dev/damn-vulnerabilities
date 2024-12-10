# Side Entrance

A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.

It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system.

You start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the designated recovery account.


Key Concepts:

Incorrect use of address(this).balance as a validation method
Solution:

flashLoan uses a non-standard approach, where it checks if the loan is repaid simply by comparing the pool’s balance if (address(this).balance < balanceBefore).
So, by borrowing through flashLoan and then depositing the funds back into the pool, it counts as repayment. Meanwhile, since you have proof of deposit in the contract, you can execute a withdraw and transfer the funds out.
