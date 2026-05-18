// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

abstract contract StarterKitBase is Script {
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 internal constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

  function _deployProxy(address implementation, bytes memory initData) internal returns (address) {
    return address(new ERC1967Proxy(implementation, initData));
  }

  function _logAddress(string memory label, address value) internal pure {
    console.log(label, value);
    console.log(string.concat("export ", label, "=", vm.toString(value)));
  }

  function _exportAddress(string memory label, address value) internal pure returns (string memory) {
    return string.concat("export ", label, "=", vm.toString(value));
  }

  function _printExportBlock(string memory exportBlock) internal pure {
    console.log("");
    console.log("Paste this block into your shell:");
    console.log(exportBlock);
  }

  function _logBytes32(string memory label, bytes32 value) internal pure {
    console.log(label, uint256(value));
  }
}
