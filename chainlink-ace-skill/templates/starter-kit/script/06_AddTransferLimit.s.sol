// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {ERC20TransferExtractor} from "@chainlink/policy-management/extractors/ERC20TransferExtractor.sol";
import {MaxPolicy} from "@chainlink/policy-management/policies/MaxPolicy.sol";
import {console} from "forge-std/console.sol";
import {StarterKitBase} from "./utils/StarterKitBase.s.sol";

contract AddTransferLimit is StarterKitBase {
  function run() external {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerKey);
    address policyEngineAddress = vm.envAddress("POLICY_ENGINE_ADDRESS");
    address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
    address extractorAddress = vm.envAddress("TRANSFER_EXTRACTOR_ADDRESS");
    uint256 maxAmount = vm.envOr("MAX_TRANSFER_AMOUNT", uint256(10_000e6));

    vm.startBroadcast(deployerKey);

    PolicyEngine policyEngine = PolicyEngine(policyEngineAddress);
    MaxPolicy maxPolicyImpl = new MaxPolicy();
    MaxPolicy maxPolicy = MaxPolicy(
      _deployProxy(
        address(maxPolicyImpl),
        abi.encodeWithSelector(Policy.initialize.selector, policyEngineAddress, deployer, abi.encode(maxAmount))
      )
    );

    ERC20TransferExtractor transferExtractor = ERC20TransferExtractor(extractorAddress);
    bytes32[] memory amountParam = new bytes32[](1);
    amountParam[0] = transferExtractor.PARAM_AMOUNT();

    policyEngine.addPolicy(tokenAddress, IERC20.transfer.selector, address(maxPolicy), amountParam);
    policyEngine.addPolicy(tokenAddress, IERC20.transferFrom.selector, address(maxPolicy), amountParam);

    vm.stopBroadcast();

    console.log("Transfer limit policy attached.");
    console.log("MAX_POLICY_ADDRESS", address(maxPolicy));
    console.log("MAX_TRANSFER_AMOUNT", maxAmount);
    _printExportBlock(_exportAddress("MAX_POLICY_ADDRESS", address(maxPolicy)));
  }
}
