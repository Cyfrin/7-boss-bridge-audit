# Issues

Short descriptions of the issues included in the code. Warning: there might be more!

- Can move tokens from those who've approved the bridge
    - The `depositTokensToL2` function allows anyone to call it with a `from` address of any account that has approved tokens to the bridge. This allows an attacker to move tokens out of the victim account, into the bridge, and assign them to the attacker's address in L2.
    - See PoC in `testCanMoveApprovedTokensOfOtherUsers`
- Can transfer from vault to vault, potentially minting unbacked tokens in L2
    - The `depositTokensToL2` function allows specifying the `from` address, from which tokens are taken. Because the vault has given infinite approval to the bridge already, it's possible to call depositTokensToL2 and transfer tokens from the vault to itself. This allows an attacker to trigger the `Deposit` event any number of times, presumably causing the minting of unbacked tokens in L2.
    - PoC in `testCanTransferFromVaultToVault`
- Replay of withdrawals
    - Valid signatures from the bridge operator can be reused to continue executing withdrawals due to the lack of nonces (or some other replay-protection mechanism).
    - PoC in `testCanReplayWithdrawals`
- Can drain vault by calling from bridge to vault
    - The L1 part of the bridge includes low-level external call that could be used to call sensitive contracts of the bridge. Such as the vault. Because the L1BossBridge owns the L1Vault, an attacker could submit a message that targets the vault and executes is `approveTo` function. This would allow anyone to drain the vault.
    - PoC in `testCanCallVaultApproveFromBridgeAndDrainVault`
- Return bombs
    - During withdrawals, the L1 part of the bridge executes a low-level call to an arbitrary target passing all available gas. This allows a malicious target to drop a return bomb to the caller, making it pay for any amount of consumed gas.
    - No PoC
- Centralization risk
    - The bridge is centralized. If the private key of the brige owner or operator is compromised, all funds are at risk.
    - No PoC
- No event emission in withdrawal
    - Withdrawals are a sensitive mechanism. Should include an event.