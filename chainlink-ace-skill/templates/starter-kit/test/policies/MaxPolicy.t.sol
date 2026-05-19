// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {ACEStablecoin} from "../../src/ACEStablecoin.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {ERC20TransferExtractor} from "@chainlink/policy-management/extractors/ERC20TransferExtractor.sol";
import {MaxPolicy} from "@chainlink/policy-management/policies/MaxPolicy.sol";
import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";

/// @notice Boundary and reconfiguration tests for `MaxPolicy` wired through `ACEStablecoin`.
///         The Act 3 integration test proves the policy fires; this file proves the cap is
///         exact and that `setMax` reshapes enforcement live without redeploying anything.
contract MaxPolicyBoundaryTest is Test {
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  uint256 internal constant ONE_TOKEN = 1e6;
  uint256 internal constant INITIAL_CAP = 10_000 * ONE_TOKEN;

  PolicyEngine internal s_policyEngine;
  ACEStablecoin internal s_token;
  RoleBasedAccessControlPolicy internal s_rolePolicy;
  MaxPolicy internal s_maxPolicy;

  address internal s_deployer = makeAddr("deployer");
  address internal s_minter = makeAddr("minter");
  address internal s_alice = makeAddr("alice");
  address internal s_bob = makeAddr("bob");

  function setUp() public {
    vm.startPrank(s_deployer);

    s_policyEngine = PolicyEngine(
      _deployProxy(
        address(new PolicyEngine()), abi.encodeWithSelector(PolicyEngine.initialize.selector, true, s_deployer)
      )
    );

    s_token = ACEStablecoin(
      _deployProxy(
        address(new ACEStablecoin()),
        abi.encodeWithSelector(
          ACEStablecoin.initialize.selector, "Future Proof USD", "FPUSD", s_deployer, address(s_policyEngine)
        )
      )
    );

    s_rolePolicy = RoleBasedAccessControlPolicy(
      _deployProxy(
        address(new RoleBasedAccessControlPolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(s_policyEngine), s_deployer, new bytes(0))
      )
    );

    s_rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.mint.selector, MINTER_ROLE);
    s_rolePolicy.grantRole(MINTER_ROLE, s_minter);

    bytes32[] memory noParams = new bytes32[](0);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.mint.selector, address(s_rolePolicy), noParams);

    ERC20TransferExtractor extractor = new ERC20TransferExtractor();
    s_policyEngine.setExtractor(IERC20.transfer.selector, address(extractor));

    s_maxPolicy = MaxPolicy(
      _deployProxy(
        address(new MaxPolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(s_policyEngine), s_deployer, abi.encode(INITIAL_CAP))
      )
    );

    bytes32[] memory amountParam = new bytes32[](1);
    amountParam[0] = extractor.PARAM_AMOUNT();
    s_policyEngine.addPolicy(address(s_token), IERC20.transfer.selector, address(s_maxPolicy), amountParam);

    vm.stopPrank();

    vm.prank(s_minter);
    s_token.mint(s_alice, 100_000 * ONE_TOKEN);
  }

  function testTransferExactlyAtCapSucceeds() public {
    vm.prank(s_alice);
    assertTrue(s_token.transfer(s_bob, INITIAL_CAP));
  }

  function testTransferOneOverCapReverts() public {
    vm.prank(s_alice);
    vm.expectRevert();
    s_token.transfer(s_bob, INITIAL_CAP + 1);
  }

  function testOwnerCanLowerCapLive() public {
    uint256 newCap = 1_000 * ONE_TOKEN;

    vm.prank(s_deployer);
    s_maxPolicy.setMax(newCap);
    assertEq(s_maxPolicy.getMax(), newCap);

    vm.prank(s_alice);
    assertTrue(s_token.transfer(s_bob, newCap));

    vm.prank(s_alice);
    vm.expectRevert();
    s_token.transfer(s_bob, newCap + 1);
  }

  function testOwnerCanRaiseCapLive() public {
    uint256 newCap = 50_000 * ONE_TOKEN;

    vm.prank(s_deployer);
    s_maxPolicy.setMax(newCap);

    vm.prank(s_alice);
    assertTrue(s_token.transfer(s_bob, INITIAL_CAP + 1));

    vm.prank(s_alice);
    assertTrue(s_token.transfer(s_bob, newCap - INITIAL_CAP - 1));
  }

  function testNonOwnerCannotSetMax() public {
    vm.prank(s_alice);
    vm.expectRevert();
    s_maxPolicy.setMax(1);
  }

  function _deployProxy(address implementation, bytes memory initData) internal returns (address) {
    return address(new ERC1967Proxy(implementation, initData));
  }
}
