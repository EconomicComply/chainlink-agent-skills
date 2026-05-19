// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test} from "forge-std/Test.sol";
import {SanctionsList} from "../../src/policies/SanctionsList.sol";

/// @notice Focused unit tests for the `SanctionsList` storage contract — complements the end-to-end
///         Act 2 integration tests in `test/ACEStablecoin.t.sol`.
contract SanctionsListTest is Test {
  event AddedToSanctionsList(address indexed account);
  event RemovedFromSanctionsList(address indexed account);

  SanctionsList internal s_list;
  address internal s_owner = makeAddr("owner");
  address internal s_attacker = makeAddr("attacker");
  address internal s_target = makeAddr("target");

  function setUp() public {
    s_list = new SanctionsList(s_owner);
  }

  function testOwnerCanAddAndRemove() public {
    vm.expectEmit(true, false, false, true, address(s_list));
    emit AddedToSanctionsList(s_target);
    vm.prank(s_owner);
    s_list.add(s_target);

    assertTrue(s_list.isSanctioned(s_target));

    vm.expectEmit(true, false, false, true, address(s_list));
    emit RemovedFromSanctionsList(s_target);
    vm.prank(s_owner);
    s_list.remove(s_target);

    assertFalse(s_list.isSanctioned(s_target));
  }

  function testNonOwnerCannotAdd() public {
    vm.prank(s_attacker);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, s_attacker));
    s_list.add(s_target);
  }

  function testNonOwnerCannotRemove() public {
    vm.prank(s_owner);
    s_list.add(s_target);

    vm.prank(s_attacker);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, s_attacker));
    s_list.remove(s_target);

    assertTrue(s_list.isSanctioned(s_target));
  }

  function testRemovingUnknownAddressIsHarmless() public {
    vm.prank(s_owner);
    s_list.remove(s_target);
    assertFalse(s_list.isSanctioned(s_target));
  }

  function testAddingTwiceIsIdempotent() public {
    vm.startPrank(s_owner);
    s_list.add(s_target);
    s_list.add(s_target);
    vm.stopPrank();

    assertTrue(s_list.isSanctioned(s_target));
  }

  function testIsSanctionedReturnsFalseByDefault() public view {
    assertFalse(s_list.isSanctioned(s_target));
    assertFalse(s_list.isSanctioned(address(0)));
  }
}
