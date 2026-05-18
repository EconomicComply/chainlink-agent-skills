// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ACEStablecoin} from "../src/ACEStablecoin.sol";
import {console} from "forge-std/console.sol";
import {StarterKitBase} from "./utils/StarterKitBase.s.sol";

contract MintTokens is StarterKitBase {
  function run() external {
    uint256 minterKey = vm.envUint("MINTER_PRIVATE_KEY");
    address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
    address recipient = vm.envOr("MINT_RECIPIENT", vm.addr(minterKey));
    uint256 amount = vm.envOr("MINT_AMOUNT", uint256(1_000_000e6));

    vm.startBroadcast(minterKey);
    ACEStablecoin(tokenAddress).mint(recipient, amount);
    vm.stopBroadcast();

    console.log("Minted stablecoins.");
    console.log("TOKEN_ADDRESS", tokenAddress);
    console.log("RECIPIENT", recipient);
    console.log("AMOUNT", amount);
  }
}
