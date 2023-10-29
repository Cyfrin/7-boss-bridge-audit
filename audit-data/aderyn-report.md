# Table of Contents

- [Medium Issues](#medium-issues)
  - [M-1: Centralization Risk for trusted owners](#M-1)
- [Low Issues](#low-issues)
  - [L-1: Unsafe ERC20 Operations should not be used](#L-1)
- [NC Issues](#nc-issues)
  - [NC-1: Missing checks for `address(0)` when assigning values to address state variables](#NC-1)
  - [NC-2: Functions not used internally could be marked external](#NC-2)
  - [NC-3: Constants should be defined and used instead of literals](#NC-3)
  - [NC-4: Event is missing `indexed` fields](#NC-4)
  - [NC-5: The `nonReentrant` `modifier` should occur before all other modifiers](#NC-5)


# Medium Issues

<a name="M-1"></a>
## M-1: Centralization Risk for trusted owners

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

- Found in src/L1BossBridge.sol: unknown
- Found in src/L1BossBridge.sol: 2096:9:32
- Found in src/L1BossBridge.sol: 2165:9:32
- Found in src/L1BossBridge.sol: 2267:9:32
- Found in src/L1Vault.sol: unknown
- Found in src/L1Vault.sol: 404:9:34
- Found in src/TokenFactory.sol: unknown
- Found in src/TokenFactory.sol: 738:9:35


# Low Issues

<a name="L-1"></a>
## L-1: Unsafe ERC20 Operations should not be used

ERC20 functions may not behave as expected. For example: return values are not always meaningful. It is recommended to use OpenZeppelin's SafeERC20 library.

- Found in src/L1BossBridge.sol: 2575:18:32
- Found in src/L1BossBridge.sol: 3056:19:32
- Found in src/L1Vault.sol: 424:13:34


# NC Issues

<a name="NC-1"></a>
## NC-1: Missing checks for `address(0)` when assigning values to address state variables

Assigning values to address state variables without checking for `address(0)`.

- Found in src/L1Vault.sol: 317:14:34


<a name="NC-2"></a>
## NC-2: Functions not used internally could be marked external



- Found in src/L1Token.sol: 219:115:33
- Found in src/L1Vault.sol: 260:78:34
- Found in src/TokenFactory.sol: 448:37:35
- Found in src/TokenFactory.sol: 657:317:35
- Found in src/L1BossBridge.sol: 1804:260:32
- Found in src/TokenFactory.sol: 980:140:35


<a name="NC-3"></a>
## NC-3: Constants should be defined and used instead of literals



- Found in src/L1Token.sol: 310:2:33


<a name="NC-4"></a>
## NC-4: Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

- Found in src/L1BossBridge.sol: 1742:56:32
- Found in src/TokenFactory.sol: 393:49:35


<a name="NC-5"></a>
## NC-5: The `nonReentrant` `modifier` should occur before all other modifiers

This is a best-practice to protect against reentrancy in other modifiers

- Found in src/L1BossBridge.sol: 3143:567:32


