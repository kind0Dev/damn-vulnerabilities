# Climber

There’s a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the [UUPS pattern](https://eips.ethereum.org/EIPS/eip-1822).

The owner of the vault is a timelock contract. It can withdraw a limited amount of tokens every 15 days.

On the vault there’s an additional role with powers to sweep all tokens in case of an emergency.

On the timelock, only an account with a “Proposer” role can schedule actions that can be executed 1 hour later.

You must rescue all tokens from the vault and deposit them into the designated recovery account.

Essentially the vuln here is in the Timelock Contract during the execute()
* function. Firstly, it allows anyone to call it which gives us an entry point.
     
* Secondly it executes the given commands, BEFORE checking that it is ready for execution.

 * This means that we are able to schedule the command we are performing at the same time
     * as doing it so that once we complete our actions, the operation we just performed
     * was a valid operation ready for execution.
     * 
     * So which commands do we need to schedule our own actions?
     * 
     * 1. Set the Timelock Contract to have the PROPOSER role.
     * 2. Update delay of schedule execution to 0 to allow immediate execution
     * 3. Call to Vault contract to upgrade to malcious attacker controlled contract 
     *      which allows setting the sweeper to anyone.
     * 4. Call to another attacker controlled contract to handle the scheduling and sweeping
     * 
     * Once we generate the `targets` and `dataElements` values for the 4 calls above, we will need to 
     * pass that to our attacking contract to store so we don't run into recursive issues.
     * This comes from the timelock contract being unable to schedule calls itself, nor being
     * able to pass the execution data to the contract at runtime as it will also run into
     * recursion isues.
     * 
     * Then once the attacker controlled contract sweeps the funds, we run a withdraw()
     * on the contract to take the funds. 




