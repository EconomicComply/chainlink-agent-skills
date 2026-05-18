// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {ERC20TransferExtractor} from "@chainlink/policy-management/extractors/ERC20TransferExtractor.sol";
import {console} from "forge-std/console.sol";
import {SanctionsList} from "../src/policies/SanctionsList.sol";
import {SanctionsPolicy} from "../src/policies/SanctionsPolicy.sol";
import {StarterKitBase} from "./utils/StarterKitBase.s.sol";

contract AddSanctionsPolicy is StarterKitBase {
  function run() external {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerKey);
    address policyEngineAddress = vm.envAddress("POLICY_ENGINE_ADDRESS");
    address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

    vm.startBroadcast(deployerKey);

    PolicyEngine policyEngine = PolicyEngine(policyEngineAddress);
    ERC20TransferExtractor transferExtractor = new ERC20TransferExtractor();
    SanctionsList sanctionsList = new SanctionsList(deployer);
    SanctionsPolicy sanctionsPolicyImpl = new SanctionsPolicy();
    SanctionsPolicy sanctionsPolicy = SanctionsPolicy(
      _deployProxy(
        address(sanctionsPolicyImpl),
        abi.encodeWithSelector(
          Policy.initialize.selector, policyEngineAddress, deployer, abi.encode(address(sanctionsList))
        )
      )
    );

    policyEngine.setExtractor(IERC20.transfer.selector, address(transferExtractor));
    policyEngine.setExtractor(IERC20.transferFrom.selector, address(transferExtractor));

    bytes32[] memory transferParams = new bytes32[](2);
    transferParams[0] = transferExtractor.PARAM_FROM();
    transferParams[1] = transferExtractor.PARAM_TO();

    policyEngine.addPolicy(tokenAddress, IERC20.transfer.selector, address(sanctionsPolicy), transferParams);
    policyEngine.addPolicy(tokenAddress, IERC20.transferFrom.selector, address(sanctionsPolicy), transferParams);

    vm.stopBroadcast();

    console.log("Sanctions policy attached.");
    console.log("TRANSFER_EXTRACTOR_ADDRESS", address(transferExtractor));
    console.log("SANCTIONS_LIST_ADDRESS", address(sanctionsList));
    console.log("SANCTIONS_POLICY_ADDRESS", address(sanctionsPolicy));
    _printExportBlock(
      string.concat(
        _exportAddress("TRANSFER_EXTRACTOR_ADDRESS", address(transferExtractor)),
        "\n",
        _exportAddress("SANCTIONS_LIST_ADDRESS", address(sanctionsList)),
        "\n",
        _exportAddress("SANCTIONS_POLICY_ADDRESS", address(sanctionsPolicy))
      )
    );
  }
}
