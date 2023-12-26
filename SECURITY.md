Invariants:
* totalAssets = totalShares <= SUM(all deposits) - SUM(all withdrawals)
* SUM(all balances), totalAssets, totalShares remain constant on all ERC20 transfers (not forced ETH transfers)
* balance = balance before + deposit amount
* balance = balance before - withdraw amount

Assumptions:
* the Vault may have a supply greater than net deposits due to forced Ether transfers, this does not break any functionality or invariants
* reentrancy is possible, and also does not break any invariants