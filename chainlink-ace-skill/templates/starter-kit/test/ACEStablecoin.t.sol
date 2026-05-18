// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {ACEStablecoin} from "../src/ACEStablecoin.sol";
import {ACEStablecoinGasBaseline, ACEStablecoinGasPolicyStack} from "../src/ACEStablecoinGasHarness.sol";
import {TraditionalStablecoin} from "../src/TraditionalStablecoin.sol";
import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {PolicyEngine} from "@chainlink/policy-management/core/PolicyEngine.sol";
import {ERC20TransferExtractor} from "@chainlink/policy-management/extractors/ERC20TransferExtractor.sol";
import {MaxPolicy} from "@chainlink/policy-management/policies/MaxPolicy.sol";
import {PausePolicy} from "@chainlink/policy-management/policies/PausePolicy.sol";
import {RoleBasedAccessControlPolicy} from "@chainlink/policy-management/policies/RoleBasedAccessControlPolicy.sol";
import {SanctionsList} from "../src/policies/SanctionsList.sol";
import {SanctionsPolicy} from "../src/policies/SanctionsPolicy.sol";

contract ACEStablecoinTest is Test {
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 internal constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

  uint256 internal constant ONE_TOKEN = 1e6;

  PolicyEngine internal s_policyEngine;
  ACEStablecoin internal s_token;
  RoleBasedAccessControlPolicy internal s_rolePolicy;
  PausePolicy internal s_pausePolicy;

  address internal s_deployer = makeAddr("deployer");
  address internal s_minter = makeAddr("minter");
  address internal s_freezer = makeAddr("freezer");
  address internal s_alice = makeAddr("alice");
  address internal s_bob = makeAddr("bob");
  address internal s_sanctioned = makeAddr("sanctioned");
  address internal s_spender = makeAddr("spender");

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

    s_pausePolicy = PausePolicy(
      _deployProxy(
        address(new PausePolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(s_policyEngine), s_deployer, abi.encode(false))
      )
    );

    s_rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.mint.selector, MINTER_ROLE);
    s_rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.burn.selector, BURNER_ROLE);
    s_rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.freeze.selector, FREEZER_ROLE);
    s_rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.unfreeze.selector, FREEZER_ROLE);

    bytes32[] memory noParams = new bytes32[](0);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.mint.selector, address(s_rolePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.burn.selector, address(s_rolePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.freeze.selector, address(s_rolePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.unfreeze.selector, address(s_rolePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.mint.selector, address(s_pausePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.burn.selector, address(s_pausePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.freeze.selector, address(s_pausePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.unfreeze.selector, address(s_pausePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.transfer.selector, address(s_pausePolicy), noParams);
    s_policyEngine.addPolicy(address(s_token), ACEStablecoin.transferFrom.selector, address(s_pausePolicy), noParams);

    vm.stopPrank();
  }

  function testAct1AuthorizedMinterCanMint() public {
    _grantRole(MINTER_ROLE, s_minter);

    vm.prank(s_minter);
    s_token.mint(s_alice, 1_000 * ONE_TOKEN);

    assertEq(s_token.balanceOf(s_alice), 1_000 * ONE_TOKEN);
  }

  function testAct1UnauthorizedMinterReverts() public {
    _grantRole(MINTER_ROLE, s_minter);

    vm.prank(s_alice);
    vm.expectRevert();
    s_token.mint(s_alice, 1_000 * ONE_TOKEN);
  }

  function testAct1RevokedMinterCannotMint() public {
    _grantRole(MINTER_ROLE, s_minter);

    vm.prank(s_minter);
    s_token.mint(s_alice, 1_000 * ONE_TOKEN);

    vm.prank(s_deployer);
    s_rolePolicy.revokeRole(MINTER_ROLE, s_minter);

    vm.prank(s_minter);
    vm.expectRevert();
    s_token.mint(s_bob, 1_000 * ONE_TOKEN);
  }

  function testAct1PauseBlocksTransfers() public {
    _grantRole(MINTER_ROLE, s_minter);

    vm.prank(s_minter);
    s_token.mint(s_alice, 1_000 * ONE_TOKEN);

    vm.prank(s_deployer);
    s_pausePolicy.setPausedState(true);

    vm.prank(s_alice);
    vm.expectRevert();
    s_token.transfer(s_bob, 100 * ONE_TOKEN);
  }

  function testAct1FreezeBlocksTransfers() public {
    _grantRole(MINTER_ROLE, s_minter);
    _grantRole(FREEZER_ROLE, s_freezer);

    vm.prank(s_minter);
    s_token.mint(s_alice, 1_000 * ONE_TOKEN);

    vm.prank(s_freezer);
    s_token.freeze(s_alice);

    vm.prank(s_alice);
    vm.expectRevert("ACEStablecoin: sender frozen");
    s_token.transfer(s_bob, 100 * ONE_TOKEN);
  }

  function testAct2SanctionsBlockRecipientAndSenderWithoutContractChanges() public {
    _grantRole(MINTER_ROLE, s_minter);
    (SanctionsList sanctionsList,) = _addSanctionsPolicy();

    vm.startPrank(s_minter);
    s_token.mint(s_alice, 2_000 * ONE_TOKEN);
    s_token.mint(s_sanctioned, 2_000 * ONE_TOKEN);
    vm.stopPrank();

    vm.prank(s_deployer);
    sanctionsList.add(s_sanctioned);

    vm.prank(s_alice);
    vm.expectRevert();
    s_token.transfer(s_sanctioned, 100 * ONE_TOKEN);

    vm.prank(s_sanctioned);
    vm.expectRevert();
    s_token.transfer(s_bob, 100 * ONE_TOKEN);

    vm.prank(s_deployer);
    sanctionsList.remove(s_sanctioned);

    vm.prank(s_alice);
    assertTrue(s_token.transfer(s_bob, 100 * ONE_TOKEN));
  }

  function testAct2SanctionsAlsoBlockTransferFrom() public {
    _grantRole(MINTER_ROLE, s_minter);
    (SanctionsList sanctionsList,) = _addSanctionsPolicy();

    vm.startPrank(s_minter);
    s_token.mint(s_alice, 2_000 * ONE_TOKEN);
    s_token.mint(s_sanctioned, 2_000 * ONE_TOKEN);
    vm.stopPrank();

    vm.prank(s_alice);
    s_token.approve(s_spender, type(uint256).max);

    vm.prank(s_sanctioned);
    s_token.approve(s_spender, type(uint256).max);

    vm.prank(s_deployer);
    sanctionsList.add(s_sanctioned);

    vm.prank(s_spender);
    vm.expectRevert();
    s_token.transferFrom(s_alice, s_sanctioned, 100 * ONE_TOKEN);

    vm.prank(s_spender);
    vm.expectRevert();
    s_token.transferFrom(s_sanctioned, s_bob, 100 * ONE_TOKEN);
  }

  function testAct3TransferLimitAddsFuturePolicyWithoutTokenChanges() public {
    _grantRole(MINTER_ROLE, s_minter);
    _addSanctionsPolicy();
    _addTransferLimit(10_000 * ONE_TOKEN);

    vm.prank(s_minter);
    s_token.mint(s_alice, 20_000 * ONE_TOKEN);

    vm.prank(s_alice);
    assertTrue(s_token.transfer(s_bob, 5_000 * ONE_TOKEN));

    vm.prank(s_alice);
    vm.expectRevert();
    s_token.transfer(s_bob, 15_000 * ONE_TOKEN);
  }

  function testAct3TransferLimitAlsoAppliesToTransferFrom() public {
    _grantRole(MINTER_ROLE, s_minter);
    _addSanctionsPolicy();
    _addTransferLimit(10_000 * ONE_TOKEN);

    vm.prank(s_minter);
    s_token.mint(s_alice, 20_000 * ONE_TOKEN);

    vm.prank(s_alice);
    s_token.approve(s_spender, type(uint256).max);

    vm.prank(s_spender);
    assertTrue(s_token.transferFrom(s_alice, s_bob, 5_000 * ONE_TOKEN));

    vm.prank(s_spender);
    vm.expectRevert();
    s_token.transferFrom(s_alice, s_bob, 15_000 * ONE_TOKEN);
  }

  function testGas_OZMint() public {
    TraditionalStablecoin token = new TraditionalStablecoin("Traditional USD", "TUSD", address(this));
    token.mint(address(0xA11CE), 1_000 * ONE_TOKEN);
  }

  function testGas_ACEMint() public {
    (
      ACEStablecoinGasBaseline token,
      RoleBasedAccessControlPolicy rolePolicy,
      PausePolicy pausePolicy,
      PolicyEngine policyEngine
    ) = _deployBaselineGasStack();
    pausePolicy;
    policyEngine;
    rolePolicy.grantRole(MINTER_ROLE, address(this));
    token.mint(address(0xA11CE), 1_000 * ONE_TOKEN);
  }

  function testGas_OZTransfer() public {
    TraditionalStablecoin token = new TraditionalStablecoin("Traditional USD", "TUSD", address(this));
    token.mint(address(this), 1_000 * ONE_TOKEN);
    token.transfer(address(0xB0B), 100 * ONE_TOKEN);
  }

  function testGas_ACETransfer() public {
    (
      ACEStablecoinGasBaseline token,
      RoleBasedAccessControlPolicy rolePolicy,
      PausePolicy pausePolicy,
      PolicyEngine policyEngine
    ) = _deployBaselineGasStack();
    pausePolicy;
    policyEngine;
    rolePolicy.grantRole(MINTER_ROLE, address(this));
    token.mint(address(this), 1_000 * ONE_TOKEN);
    token.transfer(address(0xB0B), 100 * ONE_TOKEN);
  }

  function testGas_ACETransferWithPolicies() public {
    (
      ACEStablecoinGasPolicyStack token,
      RoleBasedAccessControlPolicy rolePolicy,
      PausePolicy pausePolicy,
      PolicyEngine policyEngine
    ) = _deployPolicyStackGasToken();
    pausePolicy;
    policyEngine;
    rolePolicy.grantRole(MINTER_ROLE, address(this));

    token.mint(address(this), 1_000 * ONE_TOKEN);
    token.transfer(address(0xB0B), 100 * ONE_TOKEN);
  }

  function testGas_OZPause() public {
    TraditionalStablecoin token = new TraditionalStablecoin("Traditional USD", "TUSD", address(this));
    token.pause();
  }

  function testGas_ACEPause() public {
    vm.prank(s_deployer);
    s_pausePolicy.setPausedState(true);
  }

  function _addSanctionsPolicy() internal returns (SanctionsList sanctionsList, SanctionsPolicy sanctionsPolicy) {
    vm.startPrank(s_deployer);

    ERC20TransferExtractor extractor = new ERC20TransferExtractor();
    sanctionsList = new SanctionsList(s_deployer);
    sanctionsPolicy = SanctionsPolicy(
      _deployProxy(
        address(new SanctionsPolicy()),
        abi.encodeWithSelector(
          Policy.initialize.selector, address(s_policyEngine), s_deployer, abi.encode(address(sanctionsList))
        )
      )
    );

    s_policyEngine.setExtractor(IERC20.transfer.selector, address(extractor));
    s_policyEngine.setExtractor(IERC20.transferFrom.selector, address(extractor));

    bytes32[] memory transferParams = new bytes32[](2);
    transferParams[0] = extractor.PARAM_FROM();
    transferParams[1] = extractor.PARAM_TO();

    s_policyEngine.addPolicy(address(s_token), IERC20.transfer.selector, address(sanctionsPolicy), transferParams);
    s_policyEngine.addPolicy(address(s_token), IERC20.transferFrom.selector, address(sanctionsPolicy), transferParams);

    vm.stopPrank();
  }

  function _addTransferLimit(uint256 maxAmount) internal returns (MaxPolicy maxPolicy) {
    vm.startPrank(s_deployer);

    maxPolicy = MaxPolicy(
      _deployProxy(
        address(new MaxPolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(s_policyEngine), s_deployer, abi.encode(maxAmount))
      )
    );

    ERC20TransferExtractor extractor = ERC20TransferExtractor(s_policyEngine.getExtractor(IERC20.transfer.selector));
    bytes32[] memory amountParam = new bytes32[](1);
    amountParam[0] = extractor.PARAM_AMOUNT();

    s_policyEngine.addPolicy(address(s_token), IERC20.transfer.selector, address(maxPolicy), amountParam);
    s_policyEngine.addPolicy(address(s_token), IERC20.transferFrom.selector, address(maxPolicy), amountParam);

    vm.stopPrank();
  }

  function _grantRole(bytes32 role, address account) internal {
    vm.prank(s_deployer);
    s_rolePolicy.grantRole(role, account);
  }

  function _deployBaselineGasStack()
    internal
    returns (
      ACEStablecoinGasBaseline token,
      RoleBasedAccessControlPolicy rolePolicy,
      PausePolicy pausePolicy,
      PolicyEngine policyEngine
    )
  {
    policyEngine = PolicyEngine(
      _deployProxy(
        address(new PolicyEngine()), abi.encodeWithSelector(PolicyEngine.initialize.selector, true, address(this))
      )
    );

    token = ACEStablecoinGasBaseline(
      _deployProxy(
        address(new ACEStablecoinGasBaseline()),
        abi.encodeWithSelector(
          ACEStablecoin.initialize.selector, "Future Proof USD", "FPUSD", address(this), address(policyEngine)
        )
      )
    );

    rolePolicy = RoleBasedAccessControlPolicy(
      _deployProxy(
        address(new RoleBasedAccessControlPolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), address(this), new bytes(0))
      )
    );

    pausePolicy = PausePolicy(
      _deployProxy(
        address(new PausePolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), address(this), abi.encode(false))
      )
    );

    rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.mint.selector, MINTER_ROLE);

    bytes32[] memory noParams = new bytes32[](0);
    policyEngine.addPolicy(address(token), ACEStablecoin.mint.selector, address(rolePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.mint.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.transfer.selector, address(pausePolicy), noParams);
  }

  function _deployPolicyStackGasToken()
    internal
    returns (
      ACEStablecoinGasPolicyStack token,
      RoleBasedAccessControlPolicy rolePolicy,
      PausePolicy pausePolicy,
      PolicyEngine policyEngine
    )
  {
    policyEngine = PolicyEngine(
      _deployProxy(
        address(new PolicyEngine()), abi.encodeWithSelector(PolicyEngine.initialize.selector, true, address(this))
      )
    );

    token = ACEStablecoinGasPolicyStack(
      _deployProxy(
        address(new ACEStablecoinGasPolicyStack()),
        abi.encodeWithSelector(
          ACEStablecoin.initialize.selector, "Future Proof USD", "FPUSD", address(this), address(policyEngine)
        )
      )
    );

    rolePolicy = RoleBasedAccessControlPolicy(
      _deployProxy(
        address(new RoleBasedAccessControlPolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), address(this), new bytes(0))
      )
    );

    pausePolicy = PausePolicy(
      _deployProxy(
        address(new PausePolicy()),
        abi.encodeWithSelector(Policy.initialize.selector, address(policyEngine), address(this), abi.encode(false))
      )
    );

    rolePolicy.grantOperationAllowanceToRole(ACEStablecoin.mint.selector, MINTER_ROLE);

    bytes32[] memory noParams = new bytes32[](0);
    policyEngine.addPolicy(address(token), ACEStablecoin.mint.selector, address(rolePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.mint.selector, address(pausePolicy), noParams);
    policyEngine.addPolicy(address(token), ACEStablecoin.transfer.selector, address(pausePolicy), noParams);

    ERC20TransferExtractor extractor = new ERC20TransferExtractor();
    policyEngine.setExtractor(IERC20.transfer.selector, address(extractor));
    policyEngine.setExtractor(IERC20.transferFrom.selector, address(extractor));

    SanctionsList sanctionsList = new SanctionsList(address(this));
    SanctionsPolicy sanctionsPolicy = SanctionsPolicy(
      _deployProxy(
        address(new SanctionsPolicy()),
        abi.encodeWithSelector(
          Policy.initialize.selector, address(policyEngine), address(this), abi.encode(address(sanctionsList))
        )
      )
    );

    MaxPolicy maxPolicy = MaxPolicy(
      _deployProxy(
        address(new MaxPolicy()),
        abi.encodeWithSelector(
          Policy.initialize.selector, address(policyEngine), address(this), abi.encode(10_000 * ONE_TOKEN)
        )
      )
    );

    bytes32[] memory transferParams = new bytes32[](2);
    transferParams[0] = extractor.PARAM_FROM();
    transferParams[1] = extractor.PARAM_TO();

    bytes32[] memory amountParam = new bytes32[](1);
    amountParam[0] = extractor.PARAM_AMOUNT();

    policyEngine.addPolicy(address(token), IERC20.transfer.selector, address(sanctionsPolicy), transferParams);
    policyEngine.addPolicy(address(token), IERC20.transfer.selector, address(maxPolicy), amountParam);
  }

  function _deployProxy(address implementation, bytes memory initData) internal returns (address) {
    return address(new ERC1967Proxy(implementation, initData));
  }
}
