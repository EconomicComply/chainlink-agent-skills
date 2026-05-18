// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";
import {console} from "forge-std/console.sol";
import {StarterKitBase} from "./utils/StarterKitBase.s.sol";

contract GrantMintRole is StarterKitBase {
  function run() external {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    string memory roleName = vm.envOr("ROLE_NAME", string("MINTER"));
    address rolePolicyAddress = vm.envAddress("RBAC_POLICY_ADDRESS");
    string memory roleAction = vm.envOr("ROLE_ACTION", string("grant"));
    address roleRecipient = _resolveRoleRecipient(deployerKey, roleName);
    bytes32 role = _resolveRole(roleName);

    vm.startBroadcast(deployerKey);
    if (_isRevoke(roleAction)) {
      RoleBasedAccessControlPolicy(rolePolicyAddress).revokeRole(role, roleRecipient);
    } else {
      RoleBasedAccessControlPolicy(rolePolicyAddress).grantRole(role, roleRecipient);
    }
    vm.stopBroadcast();

    console.log(_isRevoke(roleAction) ? "Revoked role." : "Granted role.");
    console.log("ROLE_NAME", roleName);
    console.log("ROLE_RECIPIENT", roleRecipient);
    console.log("RBAC_POLICY_ADDRESS", rolePolicyAddress);
    _printExportBlock(
      string.concat(
        _exportAddress("ROLE_RECIPIENT", roleRecipient), "\n", _exportAddress("RBAC_POLICY_ADDRESS", rolePolicyAddress)
      )
    );
  }

  function _isRevoke(string memory roleAction) internal pure returns (bool) {
    return keccak256(bytes(roleAction)) == keccak256(bytes("revoke"));
  }

  function _resolveRole(string memory roleName) internal pure returns (bytes32) {
    bytes32 roleNameHash = keccak256(bytes(roleName));

    if (roleNameHash == keccak256(bytes("MINTER"))) {
      return MINTER_ROLE;
    }
    if (roleNameHash == keccak256(bytes("BURNER"))) {
      return BURNER_ROLE;
    }
    if (roleNameHash == keccak256(bytes("FREEZER"))) {
      return FREEZER_ROLE;
    }

    revert("Unsupported ROLE_NAME");
  }

  function _resolveRoleRecipient(uint256 deployerKey, string memory roleName) internal view returns (address) {
    address defaultRecipient =
      keccak256(bytes(roleName)) == keccak256(bytes("MINTER")) ? vm.envAddress("MINTER_ADDRESS") : vm.addr(deployerKey);

    return vm.envOr("ROLE_RECIPIENT", defaultRecipient);
  }
}
