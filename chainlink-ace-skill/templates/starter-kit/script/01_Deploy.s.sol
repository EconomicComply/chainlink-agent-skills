// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ACEStablecoin} from "../src/ACEStablecoin.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {PausePolicy} from "@chainlink/policy-management/policies/PausePolicy.sol";
import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {StarterKitBase} from "./utils/StarterKitBase.s.sol";

contract DeployStarterKit is StarterKitBase {
  function run() external {
    HelperConfig.NetworkConfig memory config = _getNetworkConfig();
    _announceNetwork("01_Deploy");

    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerKey);
    string memory tokenName = vm.envOr("TOKEN_NAME", config.defaultTokenName);
    string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", config.defaultTokenSymbol);

    vm.startBroadcast(deployerKey);

    PolicyEngine policyEngineImpl = new PolicyEngine();
    PolicyEngine policyEngine = PolicyEngine(
      _deployProxy(address(policyEngineImpl), abi.encodeWithSelector(PolicyEngine.initialize.selector, true, deployer))
    );

    ACEStablecoin tokenImpl = new ACEStablecoin();
    ACEStablecoin token = ACEStablecoin(
      _deployProxy(
        address(tokenImpl),
        abi.encodeWithSelector(
          ACEStablecoin.initialize.selector, tokenName, tokenSymbol, deployer, address(policyEngine)
        )
      )
    );

    RoleBasedAccessControlPolicy rolePolicyImpl = new RoleBasedAccessControlPolicy();
    RoleBasedAccessControlPolicy rolePolicy = RoleBasedAccessControlPolicy(
      _deployProxy(
        address(rolePolicyImpl),
        abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), deployer, new bytes(0))
      )
    );

    PausePolicy pausePolicyImpl = new PausePolicy();
    PausePolicy pausePolicy = PausePolicy(
      _deployProxy(
        address(pausePolicyImpl),
        abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), deployer, abi.encode(false))
      )
    );

    rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.mint.selector, MINTER_ROLE);
    rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.burn.selector, BURNER_ROLE);
    rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.freeze.selector, FREEZER_ROLE);
    rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.unfreeze.selector, FREEZER_ROLE);

    bytes32[] memory noParams = new bytes32[](0);
    policyEngine.addPolicy(address(token), ACEStablecoin.mint.selector, address(rolePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.burn.selector, address(rolePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.freeze.selector, address(rolePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.unfreeze.selector, address(rolePolicy), noParams);

    policyEngine.addPolicy(address(token), ACEStablecoin.mint.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.burn.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.freeze.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.unfreeze.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.transfer.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.transferFrom.selector, address(pausePolicy), noParams);

    vm.stopBroadcast();

    console.log("Starter kit deployed.");
    console.log("POLICY_ENGINE_ADDRESS", address(policyEngine));
    console.log("TOKEN_ADDRESS", address(token));
    console.log("RBAC_POLICY_ADDRESS", address(rolePolicy));
    console.log("PAUSE_POLICY_ADDRESS", address(pausePolicy));
    _printExportBlock(
      string.concat(
        _exportAddress("POLICY_ENGINE_ADDRESS", address(policyEngine)),
        "\n",
        _exportAddress("TOKEN_ADDRESS", address(token)),
        "\n",
        _exportAddress("RBAC_POLICY_ADDRESS", address(rolePolicy)),
        "\n",
        _exportAddress("PAUSE_POLICY_ADDRESS", address(pausePolicy))
      )
    );
  }
}
