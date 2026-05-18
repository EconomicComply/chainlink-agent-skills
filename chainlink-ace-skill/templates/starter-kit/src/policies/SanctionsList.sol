// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SanctionsList is Ownable {
  mapping(address account => bool sanctioned) private s_sanctionedAccounts;

  event AddedToSanctionsList(address indexed account);
  event RemovedFromSanctionsList(address indexed account);

  constructor(address initialOwner) Ownable(initialOwner) {}

  function add(address account) external onlyOwner {
    s_sanctionedAccounts[account] = true;
    emit AddedToSanctionsList(account);
  }

  function remove(address account) external onlyOwner {
    s_sanctionedAccounts[account] = false;
    emit RemovedFromSanctionsList(account);
  }

  function isSanctioned(address account) external view returns (bool) {
    return s_sanctionedAccounts[account];
  }
}
