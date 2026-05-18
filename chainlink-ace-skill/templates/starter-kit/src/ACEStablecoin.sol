// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PolicyProtectedUpgradeable} from "@chainlink/policy-management/core/PolicyProtectedUpgradeable.sol";

contract ACEStablecoin is Initializable, ERC20Upgradeable, PolicyProtectedUpgradeable {
  mapping(address account => bool frozen) private s_frozenAccounts;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);

  function initialize(
    string calldata name,
    string calldata symbol,
    address initialOwner,
    address policyEngine
  )
    external
    initializer
  {
    __ERC20_init(name, symbol);
    __PolicyProtected_init(initialOwner, policyEngine);
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }

  function mint(address to, uint256 amount) external runPolicy {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external runPolicy {
    _burn(from, amount);
  }

  function freeze(address account) external runPolicy {
    s_frozenAccounts[account] = true;
    emit AccountFrozen(account);
  }

  function unfreeze(address account) external runPolicy {
    s_frozenAccounts[account] = false;
    emit AccountUnfrozen(account);
  }

  function transfer(address to, uint256 value) public override runPolicy returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public override runPolicy returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function isFrozen(address account) external view returns (bool) {
    return s_frozenAccounts[account];
  }

  function _update(address from, address to, uint256 value) internal override {
    if (from != address(0)) {
      require(!s_frozenAccounts[from], "ACEStablecoin: sender frozen");
    }

    if (to != address(0)) {
      require(!s_frozenAccounts[to], "ACEStablecoin: recipient frozen");
    }

    super._update(from, to, value);
  }
}
