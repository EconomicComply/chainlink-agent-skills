// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract TraditionalStablecoin is ERC20, AccessControl, Pausable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  mapping(address account => bool frozen) private s_frozenAccounts;
  mapping(address account => bool blacklisted) private s_blacklistedAccounts;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);
  event AccountBlacklisted(address indexed account);
  event AccountUnblacklisted(address indexed account);

  constructor(string memory name, string memory symbol, address admin) ERC20(name, symbol) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MINTER_ROLE, admin);
    _grantRole(BURNER_ROLE, admin);
    _grantRole(FREEZER_ROLE, admin);
    _grantRole(PAUSER_ROLE, admin);
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }

  function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) whenNotPaused {
    _burn(from, amount);
  }

  function freeze(address account) external onlyRole(FREEZER_ROLE) whenNotPaused {
    s_frozenAccounts[account] = true;
    emit AccountFrozen(account);
  }

  function unfreeze(address account) external onlyRole(FREEZER_ROLE) whenNotPaused {
    s_frozenAccounts[account] = false;
    emit AccountUnfrozen(account);
  }

  function blacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    s_blacklistedAccounts[account] = true;
    emit AccountBlacklisted(account);
  }

  function unblacklist(address account) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    s_blacklistedAccounts[account] = false;
    emit AccountUnblacklisted(account);
  }

  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function isFrozen(address account) external view returns (bool) {
    return s_frozenAccounts[account];
  }

  function isBlacklisted(address account) external view returns (bool) {
    return s_blacklistedAccounts[account];
  }

  function _update(address from, address to, uint256 value) internal override whenNotPaused {
    if (from != address(0)) {
      require(!s_frozenAccounts[from], "TraditionalStablecoin: sender frozen");
      require(!s_blacklistedAccounts[from], "TraditionalStablecoin: sender blacklisted");
    }

    if (to != address(0)) {
      require(!s_frozenAccounts[to], "TraditionalStablecoin: recipient frozen");
      require(!s_blacklistedAccounts[to], "TraditionalStablecoin: recipient blacklisted");
    }

    super._update(from, to, value);
  }
}
