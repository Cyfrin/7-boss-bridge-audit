// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/interfaces/IERC20.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract L1Vault is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function approveTo(address target, uint256 amount) external onlyOwner {
        token.approve(target, amount);
    }
}
