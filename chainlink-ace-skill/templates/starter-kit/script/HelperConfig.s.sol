// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";

/// @notice Centralised per-network defaults used by the starter-kit deployment scripts.
/// @dev Env vars (TOKEN_NAME / TOKEN_SYMBOL / PRIVATE_KEY etc.) always win over what is set here —
///      this contract only supplies fallbacks and human-readable labels per chain.
contract HelperConfig is Script {
  struct NetworkConfig {
    string name;
    bool isLocal;
    string defaultTokenName;
    string defaultTokenSymbol;
  }

  uint256 public constant ANVIL_CHAIN_ID = 31337;
  uint256 public constant ETHEREUM_SEPOLIA_CHAIN_ID = 11155111;
  uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
  uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
  uint256 public constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;
  uint256 public constant AVALANCHE_FUJI_CHAIN_ID = 43113;

  NetworkConfig public activeNetworkConfig;

  constructor() {
    activeNetworkConfig = getConfigByChainId(block.chainid);
  }

  function getConfigByChainId(uint256 chainId) public pure returns (NetworkConfig memory) {
    if (chainId == ANVIL_CHAIN_ID) return getAnvilConfig();
    if (chainId == ETHEREUM_SEPOLIA_CHAIN_ID) return getEthereumSepoliaConfig();
    if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) return getArbitrumSepoliaConfig();
    if (chainId == BASE_SEPOLIA_CHAIN_ID) return getBaseSepoliaConfig();
    if (chainId == OPTIMISM_SEPOLIA_CHAIN_ID) return getOptimismSepoliaConfig();
    if (chainId == AVALANCHE_FUJI_CHAIN_ID) return getAvalancheFujiConfig();
    return getUnknownConfig(chainId);
  }

  function getAnvilConfig() public pure returns (NetworkConfig memory) {
    return
      NetworkConfig({name: "Anvil", isLocal: true, defaultTokenName: "Future Proof USD", defaultTokenSymbol: "FPUSD"});
  }

  function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
      name: "Ethereum Sepolia",
      isLocal: false,
      defaultTokenName: "Future Proof USD",
      defaultTokenSymbol: "FPUSD"
    });
  }

  function getArbitrumSepoliaConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
      name: "Arbitrum Sepolia",
      isLocal: false,
      defaultTokenName: "Future Proof USD",
      defaultTokenSymbol: "FPUSD"
    });
  }

  function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
      name: "Base Sepolia",
      isLocal: false,
      defaultTokenName: "Future Proof USD",
      defaultTokenSymbol: "FPUSD"
    });
  }

  function getOptimismSepoliaConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
      name: "OP Sepolia",
      isLocal: false,
      defaultTokenName: "Future Proof USD",
      defaultTokenSymbol: "FPUSD"
    });
  }

  function getAvalancheFujiConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
      name: "Avalanche Fuji",
      isLocal: false,
      defaultTokenName: "Future Proof USD",
      defaultTokenSymbol: "FPUSD"
    });
  }

  function getUnknownConfig(
    uint256 // chainId
  )
    public
    pure
    returns (NetworkConfig memory)
  {
    return NetworkConfig({
      name: "Unknown",
      isLocal: false,
      defaultTokenName: "Future Proof USD",
      defaultTokenSymbol: "FPUSD"
    });
  }
}
