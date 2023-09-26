// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/interfaces/IERC20.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/Pausable.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./L1Vault.sol";

contract L1TokenBridge is Ownable, Pausable, ReentrancyGuard {
    uint256 public DEPOSIT_LIMIT = 100000 ether;

    IERC20 public token;
    L1Vault public vault;
    mapping(address account => bool isSigner) public signers;

    error DepositLimitReached();
    error Unauthorized();

    event Deposit(address from, address to, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
        vault = new L1Vault(token);
        // Allows the bridge to move tokens out of the vault to facilitate withdrawals
        vault.approveTo(address(this), type(uint256).max);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSigner(address account, bool enabled) external onlyOwner {
        signers[account] = enabled;
    }

    function depositTokensToL2(address from, address l2Recipient, uint256 amount) external whenNotPaused {
        if (token.balanceOf(address(vault)) + amount > DEPOSIT_LIMIT) {
            revert DepositLimitReached();
        }
        token.transferFrom(from, address(vault), amount);

        // Our off-chain service picks up this event and mints the corresponding tokens on L2
        emit Deposit(from, l2Recipient, amount);
    }

    function withdrawTokensToL1(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        sendToL1(
            v,
            r,
            s,
            abi.encode(
                address(token),
                0, // value
                abi.encodeCall(IERC20.transferFrom, (address(vault), to, amount))
            )
        );
    }

    function sendToL1(uint8 v, bytes32 r, bytes32 s, bytes memory message) public whenNotPaused nonReentrant {
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(message)), v, r, s);

        if (!signers[signer]) {
            revert Unauthorized();
        }

        (address target, uint256 value, bytes memory data) = abi.decode(message, (address, uint256, bytes));

        (bool success,) = target.call{value: value}(data);
        require(success, "External call failed");
    }
}
