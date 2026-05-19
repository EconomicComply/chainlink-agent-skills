# Starter Kit

## Trigger Conditions

Read this file when:
- The user asks for a working sample, hands-on example, scaffold, starter kit, template, or boilerplate
- The user asks for a deploy walkthrough, Anvil/Sepolia run, or wants to "try ACE end to end"
- The user asks how to wire `PolicyProtectedUpgradeable` and `runPolicy` into an ERC-20
- The user asks how to add a custom policy (sanctions, blacklist) after deploy without touching the token
- The user asks how to add a transfer cap, volume limit, or other rule to an already-deployed regulated token
- The user is starting a new stablecoin, tokenized fund, or RWA token and wants the ACE integration step done right the first time

## What the Kit Is

The bundled Foundry project at [templates/starter-kit/](../templates/starter-kit/) is a runnable demonstration of the ACE integration pattern using a regulated ERC-20 stablecoin.

- **Project root**: `chainlink-ace-skill/templates/starter-kit/`
- **Toolchain**: Foundry (Solidity 0.8.26, via-IR, optimizer 8000 runs), npm scripts wrapping `forge script`
- **Stack**: OpenZeppelin upgradeable ERC-20 + the ACE framework from the [`@chainlink/ace`](https://www.npmjs.com/package/@chainlink/ace) npm package. After `npm install`, the framework sources resolve under `node_modules/@chainlink/ace/packages/policy-management/src/` via the remapping in `remappings.txt`. The kit does not vendor the framework.
- **License**: All `.sol` files carry `SPDX-License-Identifier: BUSL-1.1`; production use requires a Chainlink commercial license

The kit's own [README.md](../templates/starter-kit/README.md) targets human developers. Use this reference doc as the agent's map of the same material.

## Directory Layout

| Path | Role |
| --- | --- |
| `src/ACEStablecoin.sol` | The protected token. The file devs adapt for their asset. |
| `src/TraditionalStablecoin.sol` | Pre-ACE comparison contract. Not deployed — kept for the README's diff. |
| `src/ACEStablecoinGasHarness.sol` | Two minimal harness tokens used by the gas-comparison tests. Not deployed. |
| `src/policies/SanctionsPolicy.sol` | Example of a custom policy. Implements `Policy.run()`. |
| `src/policies/SanctionsList.sol` | Backing storage for the custom policy. |
| `script/01_Deploy.s.sol` … `06_AddTransferLimit.s.sol` | Sequential deploy / configuration steps. |
| `script/HelperConfig.s.sol` | Multi-chain config lookup (chainId → token name/symbol, network label). Used by every step script. |
| `script/utils/StarterKitBase.s.sol` | Shared proxy-deployment helper. Used by every step script. |
| `test/ACEStablecoin.t.sol` | Integration tests for the three Acts plus an ACE-vs-OpenZeppelin gas comparison. |
| `test/policies/MaxPolicy.t.sol`, `test/policies/SanctionsList.t.sol` | Boundary tests for the policy primitives the kit relies on. |
| `foundry.toml`, `remappings.txt`, `package.json`, `.env.example` | Project scaffolding. `package.json` declares `@chainlink/ace` as a dev dependency; `remappings.txt` points `@chainlink/policy-management/` at the installed package path. `foundry.toml` defines `[rpc_endpoints]` and `[etherscan]` blocks for Sepolia-class testnets (Ethereum, Arbitrum, Base, Optimism, Avalanche Fuji). |

## The Three Acts

The walkthrough deliberately stages the value proposition. When the user asks "where does X happen," map their question to an Act:

| Act | What it proves | Scripts | Policies attached |
| --- | --- | --- | --- |
| **Act 1** — same patterns, cleaner architecture | RBAC and pause work the way OpenZeppelin teams already expect, just outside the token | `01_Deploy` → `03_MintTokens` | `RoleBasedAccessControlPolicy`, `PausePolicy` |
| **Act 2** — add compliance after deploy | A new rule (sanctions blacklist) attaches without redeploying or upgrading the token | `04_AddSanctionsPolicy`, `05_BlockAddress` | Custom `SanctionsPolicy` + `ERC20TransferExtractor` |
| **Act 3** — future-proof by default | A brand-new rule (transfer cap) lands the same way | `06_AddTransferLimit` | Built-in `MaxPolicy` |

The point Acts 2 and 3 share: the token contract is never touched again.

## What Devs Modify vs Leave Alone

| Modify freely | Modify carefully | Leave alone |
| --- | --- | --- |
| `src/ACEStablecoin.sol` state, asset-specific functions, decimals | `script/01_Deploy.s.sol` to add/remove base policies for the deployment | `script/utils/StarterKitBase.s.sol` |
| `src/policies/SanctionsPolicy.sol` for the custom rule | `runPolicy` modifier placement (every protected function needs it) | `node_modules/@chainlink/ace/**` (npm-installed library) |
| New custom policies alongside `SanctionsPolicy.sol` | The `__PolicyProtected_init(initialOwner, policyEngine)` call in `initialize` | `foundry.toml`, `remappings.txt` (unless retargeting Solidity or pinning a different `@chainlink/ace` version) |
| New chain entries in `script/HelperConfig.s.sol` and matching `foundry.toml` `[rpc_endpoints]`/`[etherscan]` blocks | `package.json` scripts and step ordering | Test files under `test/` (extend, do not delete the existing cases) |
| `package.json` dependencies (versioned bumps with audit) | The selector-to-policy attachments in deploy scripts | The selector signatures used in policy attachments (must match the token's actual function signatures) |

If the user wants to remove the freeze functionality, the asset-specific frozen-account state lives in the token (`s_frozenAccounts`) — that goes. The `runPolicy` modifier on `freeze` / `unfreeze` and the corresponding role attachments in `01_Deploy.s.sol` go with it. The `PolicyProtectedUpgradeable` mixin stays.

## The "No Redeploy" Pattern

This is the kit's central claim. Whenever a user asks for a post-deploy change, surface it as one of these moves:

1. **Attach a built-in policy.** Deploy the policy as a UUPS proxy, configure it, then call `policyEngine.addPolicy(token, selector, policyAddress, params)`. Pattern reference: `06_AddTransferLimit.s.sol`.
2. **Write and attach a custom policy.** Inherit `Policy`, implement `configure(bytes)` and `run(...)`, deploy as a UUPS proxy, then attach. Pattern reference: `SanctionsPolicy.sol` + `04_AddSanctionsPolicy.s.sol`.
3. **Reorder or remove a policy.** Call `policyEngine.removePolicy(...)` or re-attach in a new order. The token doesn't observe ordering changes.
4. **Adjust runtime parameters.** Each policy exposes setter functions for its configuration (e.g., `MaxPolicy.setMax(...)`, `SanctionsList.add(...)`). The token never sees these calls.
5. **Grant or revoke a role.** Done via `RoleBasedAccessControlPolicy`, not the token. Pattern reference: `02_ManageRole.s.sol`.

For any of these, the token bytecode and storage layout are unchanged. No upgrade, no migration, no re-audit of the token itself.

## Scaffolding Protocol

When a user accepts the kit:

1. Copy `chainlink-ace-skill/templates/starter-kit/` into the user's working directory. The kit is self-contained: `npm install` will pull `@chainlink/ace` along with OpenZeppelin and forge-std.
2. Run the Quick Start from the kit's README: `npm install` → `cp .env.example .env` → `set -a; source .env; set +a` → `npm run build` → `npm run test`. The build will not succeed before `npm install` since the framework is loaded from `node_modules/@chainlink/ace/...`.
3. Start `anvil` in a separate shell for the local walkthrough. For Sepolia, point `RPC_URL` at the user's endpoint and use funded keys.
4. Walk the user through `npm run step:01` … `step:06` in order. Each step prints a paste-ready `export ADDRESS=…` block that the user must paste into their shell before the next step.
5. Apply the SKILL.md Approval Protocol before any `forge script --broadcast` or `cast send` that touches a non-local network. The kit's `.env.example` uses sample Anvil private keys; do not reuse those on Sepolia or mainnet.

## Adapting the Kit to Another Asset

For a security token, tokenized fund, or other regulated ERC-20:

1. Rename `ACEStablecoin` to the asset name (file, contract, deploy script imports, env exports).
2. Replace asset-specific state. The frozen-account mapping is stablecoin-flavored; an RWA fund might instead carry NAV state, share-class enumerations, or transfer-window state. Keep all such state inside the token contract.
3. Keep the integration surface untouched: `PolicyProtectedUpgradeable`, `__PolicyProtected_init`, `runPolicy` on every protected entrypoint.
4. Pick the right starting policy set. RBAC + Pause is the floor for almost any regulated asset. Add `IntervalPolicy` for lock-up windows, `VolumePolicy` for daily caps, identity-gated policies for KYC/accreditation when Cross-Chain Identity is in scope.
5. Write custom policies for rules the built-in library doesn't cover. Use `SanctionsPolicy.sol` as the template — same `Policy` base class, same `configure` + `run` shape.

## Caveats and Boundaries

- The kit pins `@chainlink/ace` via npm in `package.json`. For production, review the pinned version against the latest release on `github.com/smartcontractkit/chainlink-ace`, audit any version bump, and consider committing a `package-lock.json` to lock the dependency graph.
- The kit demonstrates self-deployed OSS contracts. It is not the managed ACE Platform. For Platform/Beta questions, route through [platform-and-beta.md](platform-and-beta.md).
- The sample private keys in `.env.example` are Anvil defaults. They are public and must never reach a non-local chain.
- For mainnet or any production deployment, surface BUSL/commercial licensing, contract audit, credential-issuer trust, and operational ownership before running broadcasts.
