// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Policy} from "@chainlink/policy-management/core/Policy.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {SanctionsList} from "./SanctionsList.sol";

contract SanctionsPolicy is Policy {
  string public constant override typeAndVersion = "SanctionsPolicy 1.0.0";

  address public sanctionsList;

  function configure(bytes calldata parameters) internal override onlyInitializing {
    require(parameters.length > 0, "SanctionsPolicy: configData required");
    _setSanctionsList(abi.decode(parameters, (address)));
  }

  function setSanctionsList(address listAddress) external onlyOwner {
    _setSanctionsList(listAddress);
  }

  function run(
    address,
    address,
    bytes4,
    bytes[] calldata parameters,
    bytes calldata
  )
    public
    view
    override
    returns (IPolicyEngine.PolicyResult)
  {
    if (parameters.length != 2) {
      revert InvalidParameters("SanctionsPolicy: expected from and to");
    }

    address from = abi.decode(parameters[0], (address));
    address to = abi.decode(parameters[1], (address));
    SanctionsList list = SanctionsList(sanctionsList);

    if ((from != address(0) && list.isSanctioned(from)) || (to != address(0) && list.isSanctioned(to))) {
      revert IPolicyEngine.PolicyRejected("account sanctions validation failed");
    }

    return IPolicyEngine.PolicyResult.Continue;
  }

  function _setSanctionsList(address listAddress) private {
    require(listAddress != address(0), "SanctionsPolicy: invalid address");
    sanctionsList = listAddress;
  }
}
