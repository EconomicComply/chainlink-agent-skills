// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {SanctionsList} from "../src/policies/SanctionsList.sol";
import {StarterKitBase} from "./utils/StarterKitBase.s.sol";

contract BlockAddress is StarterKitBase {
  function run() external {
    _announceNetwork("05_BlockAddress");

    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address sanctionsListAddress = vm.envAddress("SANCTIONS_LIST_ADDRESS");
    address sanctionedAddress = vm.envAddress("SANCTIONED_ADDRESS");

    vm.startBroadcast(deployerKey);
    SanctionsList(sanctionsListAddress).add(sanctionedAddress);
    vm.stopBroadcast();

    console.log("Added address to sanctions list.");
    console.log("SANCTIONS_LIST_ADDRESS", sanctionsListAddress);
    console.log("SANCTIONED_ADDRESS", sanctionedAddress);
    _printExportBlock(
      string.concat(
        _exportAddress("SANCTIONS_LIST_ADDRESS", sanctionsListAddress),
        "\n",
        _exportAddress("SANCTIONED_ADDRESS", sanctionedAddress)
      )
    );
  }
}
