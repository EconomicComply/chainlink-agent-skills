# VRF v2.5 Official Sources

Use these URLs when reference files do not contain the specific information needed (e.g., exact key hash bytes32 values, current subscription minimums, network-specific parameters).

## Core Documentation

| Topic | URL |
|---|---|
| VRF Overview | https://docs.chain.link/vrf |
| VRF v2.5 Overview | https://docs.chain.link/vrf/v2-5/overview |
| Subscription — Get a Random Number | https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number |
| Direct Funding — Get a Random Number | https://docs.chain.link/vrf/v2-5/direct-funding/get-a-random-number |
| Migrating from V2 to v2.5 | https://docs.chain.link/vrf/v2-5/migration-from-v2 |
| Billing | https://docs.chain.link/vrf/v2-5/billing |
| Supported Networks & Addresses | https://docs.chain.link/vrf/v2-5/supported-networks |
| Security Considerations | https://docs.chain.link/vrf/v2-5/security |
| Subscription Management (UI) | https://vrf.chain.link |

## Contract Source Code

| Contract | GitHub |
|---|---|
| VRFConsumerBaseV2Plus | https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol |
| VRFV2PlusClient library | https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol |
| VRFV2PlusWrapperConsumerBase | https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol |

## npm Package

```bash
npm install @chainlink/contracts
```

Latest version: https://www.npmjs.com/package/@chainlink/contracts

## Fetching Live Data

When fetching from official docs fails or returns incomplete content:
1. Use `curl -s -L -A "Mozilla/5.0" "<url>"` as a fallback.
2. Report the URL directly to the user if both methods fail.
3. Never invent addresses, key hashes, or network parameters from training data alone.
