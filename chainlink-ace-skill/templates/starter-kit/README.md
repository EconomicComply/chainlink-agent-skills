# Future-Proof Regulated Token with ACE

> **Note**
> This repository represents an example of using a Chainlink product or service and is provided to help you understand how to interact with Chainlink's systems and services so that you can integrate them into your own. This template is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Do not use the code in this example in a production environment without completing your own audits and applying best practices. Neither Chainlink Labs, the Chainlink Foundation, nor Chainlink node operators are responsible for unintended outputs that are generated due to errors in code.

## Table of contents

- [Why this is better](#why-this-is-better)
- [What changes in your contract](#what-changes-in-your-contract)
- [Repo layout](#repo-layout)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Act 1: Same thing you already know](#act-1-same-thing-you-already-know)
- [Act 2: Add a blacklist without touching your contract](#act-2-add-a-blacklist-without-touching-your-contract)
- [Act 3: The future-proof moment](#act-3-the-future-proof-moment)
- [Running on a public testnet](#running-on-a-public-testnet)
- [Production best practices](#production-best-practices)
- [What else is possible](#what-else-is-possible)
- [What's next](#whats-next)
- [Resources](#resources)
- [License](#license)

A Foundry starter kit for stablecoin and regulated-token teams that want the same role control, pause logic, and blacklist behavior they already build today, but without hardcoding compliance into the token forever.

In under 10 minutes, you can deploy a stablecoin, replace token-level access control with ACE policies, add a blacklist after deployment, and then add a transfer cap without changing the token contract at all.

This walkthrough uses a stablecoin because the patterns are instantly recognizable: roles, pause, blacklist. If you are building a tokenized fund, a security token, or any other regulated ERC-20, the integration is identical. The only difference is which policies you attach later.

This repo is meant to be used, not just read. Run the scripts, hit the reverts in your terminal, and see why you integrate ACE once while the contract is still cheap to change, then make future compliance a configuration problem instead of a token-upgrade problem.

## Why this is better

Most stablecoins start with familiar Solidity patterns:

- `AccessControl` or `Ownable` for mint, burn, and freeze permissions
- `Pausable` for emergency stops
- `mapping(address => bool)` for blacklists or sanctions
- transfer hooks that accumulate compliance checks directly inside the token

That works until requirements change.

Every new rule means touching the token contract again, re-auditing it, and accepting redeployment or upgrade risk on the most valuable contract in the system. That is true for stablecoins and for RWA tokens that start adding KYC gates, jurisdiction checks, accredited-investor rules, lock-up periods, or trading-window restrictions. The more regulated the environment becomes, the more compliance logic gets baked directly into the token itself.

ACE changes that model.

You integrate once at the contract layer with `PolicyProtectedUpgradeable` and `runPolicy`. After that, compliance becomes configuration on the `PolicyEngine`:

- need RBAC today: attach `RoleBasedAccessControlPolicy`
- need pause controls: attach `PausePolicy`
- need a blacklist next quarter: deploy a `SanctionsPolicy` and attach it
- need transfer caps next year: deploy `MaxPolicy` and attach it

The token contract keeps doing token things. The policy layer decides who can call protected functions and under what conditions.

That gives you three benefits immediately:

- **Same patterns, cleaner architecture.** RBAC still uses role names like `MINTER_ROLE` and the same grant/revoke workflow stablecoin teams already know from OpenZeppelin.
- **Future-proof by default.** New compliance behavior becomes a new policy attachment, not a token rewrite.
- **Thinner contracts.** Your token defines what it does. The `PolicyEngine` defines who can do it and what extra rules apply.

If you are building a stablecoin, tokenized fund, or other regulated ERC-20 today, the bet is simple: do the integration work once now, while the contract is still low-risk and cheap to change, instead of doing it later when the contract is larger, more valuable, and more expensive to upgrade.

Let’s see what that looks like in code.

## What changes in your contract

The structural diff is small enough to understand at a glance.

### What you remove

- `AccessControl`, `Pausable`, and `Ownable` imports from the token
- token-level role constants and role-admin wiring
- token-level blacklist state and blacklist enforcement
- token-level pause modifiers on every protected function
- the habit of adding a new modifier or transfer hook every time compliance requirements change

### What you add

- `PolicyProtectedUpgradeable`
- a `PolicyEngine` address during initialization
- `runPolicy` on protected entrypoints such as `mint`, `burn`, `freeze`, `transfer`, and `transferFrom`

### The key insight

Your token becomes thinner because it only defines what the asset does. The policy layer defines who can call protected functions and what extra compliance checks apply.

The token still owns asset state such as balances and, in this demo, the frozen-account state. ACE owns authorization and evolving compliance logic: who may mint, who may burn, whether the token is paused, whether an address is sanctioned, whether transfers are capped, and whatever else you add later.

Traditional stablecoin:

```solidity
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract TraditionalStablecoin is ERC20, AccessControl, Pausable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  mapping(address => bool) private frozen;
  mapping(address => bool) private blacklisted;

  function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
    _mint(to, amount);
  }

  function _update(address from, address to, uint256 value) internal override whenNotPaused {
    require(!frozen[from] && !frozen[to], "frozen");
    require(!blacklisted[from] && !blacklisted[to], "blacklisted");
    super._update(from, to, value);
  }
}
```

ACE stablecoin:

```solidity
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PolicyProtectedUpgradeable} from "@chainlink/policy-management/core/PolicyProtectedUpgradeable.sol";

contract ACEStablecoin is ERC20Upgradeable, PolicyProtectedUpgradeable {
  mapping(address => bool) private frozen;

  function initialize(
    string calldata name,
    string calldata symbol,
    address initialOwner,
    address policyEngine
  ) external initializer {
    __ERC20_init(name, symbol);
    __PolicyProtected_init(initialOwner, policyEngine);
  }

  function mint(address to, uint256 amount) external runPolicy {
    _mint(to, amount);
  }

  function freeze(address account) external runPolicy {
    frozen[account] = true;
  }

  function transfer(address to, uint256 value) public override runPolicy returns (bool) {
    return super.transfer(to, value);
  }

  function _update(address from, address to, uint256 value) internal override {
    require(!frozen[from] && !frozen[to], "frozen");
    super._update(from, to, value);
  }
}
```

The important shift is:

* `runPolicy` replaces `onlyRole(...)` and `whenNotPaused`
* RBAC moves into `RoleBasedAccessControlPolicy`
* pause moves into `PausePolicy`
* blacklist logic moves into `SanctionsPolicy`
* transfer limits move into `MaxPolicy`
* freeze authorization moves into policy, while the token keeps the frozen-account state it already knows how to enforce

That is the only contract integration step that matters: wire in `PolicyProtectedUpgradeable`, initialize the `PolicyEngine`, and put `runPolicy` on protected functions. Everything else is policy configuration. Let’s set it up.

## Repo layout

```text
.
├── README.md
├── .env.example
├── package.json
├── foundry.toml
├── remappings.txt
├── src/
│   ├── TraditionalStablecoin.sol
│   ├── ACEStablecoin.sol
│   └── policies/
│       ├── SanctionsList.sol
│       └── SanctionsPolicy.sol
├── script/
│   ├── 01_Deploy.s.sol
│   ├── 02_ManageRole.s.sol
│   ├── 03_MintTokens.s.sol
│   ├── 04_AddSanctionsPolicy.s.sol
│   ├── 05_BlockAddress.s.sol
│   ├── 06_AddTransferLimit.s.sol
│   ├── HelperConfig.s.sol
│   └── utils/
└── test/
    ├── ACEStablecoin.t.sol
    └── policies/
```

`TraditionalStablecoin.sol` exists for comparison only. The walkthrough deploys only the ACE version.

The ACE framework (`@chainlink/policy-management/...` imports) is pulled from npm via the [`@chainlink/ace`](https://www.npmjs.com/package/@chainlink/ace) package, declared in `package.json`. After `npm install` the framework sources live under `node_modules/@chainlink/ace/packages/policy-management/src/` and are resolved by the remapping in `remappings.txt`. You do not need to vendor the framework or fetch a git submodule.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (latest stable) — `forge`, `cast`, and `anvil`
- [Node.js](https://nodejs.org/) `>= 20` and `npm` for the OpenZeppelin and forge-std packages
- A funded EOA on whichever public testnet you plan to use (see [Running on a public testnet](#running-on-a-public-testnet))
- Block-explorer API keys if you want to verify contracts (`ETHERSCAN_API_KEY`, `ARBISCAN_API_KEY`, etc.)

## Quick start

This walkthrough is Anvil-first so you can see the full story locally in minutes. Public testnets are covered later once you want to run the same flow against a shared chain.

Install dependencies (this pulls `@chainlink/ace`, OpenZeppelin, and forge-std):

```bash
npm install
```

Copy the example env file:

```bash
cp .env.example .env
```

Set your environment:

```bash
set -a
source .env
set +a
```

Build and test:

```bash
npm run build
npm run test
```

Start a local chain in a separate terminal:

```bash
anvil
```

Every script uses `--rpc-url "$RPC_URL"`, so once you are done locally you can point the same flow at Sepolia later.

### What you will prove in this walkthrough

* **Act 1:** ACE handles the same RBAC and emergency-stop patterns you already use
* **Act 2:** you can add a blacklist after deployment without changing the token
* **Act 3:** you can add a brand new transfer rule later without changing the token

The goal is not just to deploy contracts. The goal is to feel the architecture change in your terminal.

## Act 1: Same thing you already know

This is the familiar stablecoin setup, but with the logic moved out of the token. It is also where many RWA tokens begin before they layer on investor and jurisdiction controls:

* deploy the ACE token plus `PolicyEngine`
* attach `RoleBasedAccessControlPolicy`
* attach `PausePolicy`
* grant a minter
* mint tokens
* prove unauthorized minting fails
* prove pausing blocks transfers

The mapping to familiar OpenZeppelin patterns is direct:

* `RoleBasedAccessControlPolicy` is the replacement for token-level `AccessControl`
* `PausePolicy` is the replacement for token-level `Pausable`
* role grant/revoke still works the same way
* selector-to-role mapping replaces hardcoded `onlyRole(...)` modifiers

### Step 1. Deploy the token and base policies

```bash
npm run step:01
```

Script: [script/01_Deploy.s.sol](script/01_Deploy.s.sol)

This deploys:

* `PolicyEngine`
* `ACEStablecoin`
* `RoleBasedAccessControlPolicy`
* `PausePolicy`

It also attaches:

* RBAC to `mint`, `burn`, `freeze`, and `unfreeze`
* pause checks to `mint`, `burn`, `freeze`, `unfreeze`, `transfer`, and `transferFrom`

At the end, the script prints one paste-ready block of `export ...` commands for the deployed addresses. Copy that block into the same shell before moving to step 2.

### Step 2. Grant the minter role

```bash
npm run step:02
```

Script: [script/02_ManageRole.s.sol](script/02_ManageRole.s.sol)

This grants `MINTER_ROLE` to `MINTER_ADDRESS`.

That should feel familiar: same role name, same grant workflow, different location. The role is enforced by policy instead of by the token contract.

### Step 3. Mint tokens

```bash
npm run step:03
```

Script: [script/03_MintTokens.s.sol](script/03_MintTokens.s.sol)

By default the script mints `20,000` tokens with `6` decimals to `ALICE_ADDRESS`.

### Step 4. Live proof

Authorized minter succeeds:

```bash
cast send "$TOKEN_ADDRESS" \
  "mint(address,uint256)" "$ALICE_ADDRESS" 1000000000 \
  --private-key "$MINTER_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Unauthorized mint reverts:

```bash
cast send "$TOKEN_ADDRESS" \
  "mint(address,uint256)" "$ALICE_ADDRESS" 1000000000 \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Revoke the minter role without redeploying the token:

```bash
ROLE_ACTION=revoke npm run step:02
```

Minting from the revoked account now reverts:

```bash
cast send "$TOKEN_ADDRESS" \
  "mint(address,uint256)" "$ALICE_ADDRESS" 1000000000 \
  --private-key "$MINTER_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Grant the minter role back so the rest of the walkthrough can keep using the same minter account:

```bash
ROLE_ACTION=grant npm run step:02
```

Pause the token:

```bash
cast send "$PAUSE_POLICY_ADDRESS" \
  "setPausedState(bool)" true \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Paused transfer reverts:

```bash
cast send "$TOKEN_ADDRESS" \
  "transfer(address,uint256)" "$BOB_ADDRESS" 100000000 \
  --private-key "$ALICE_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Unpause so the next acts can continue:

```bash
cast send "$PAUSE_POLICY_ADDRESS" \
  "setPausedState(bool)" false \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Takeaway: this is the same RBAC and emergency-stop workflow stablecoin developers already know. The difference is that the rules live outside the token.

Freeze an account with the same familiar stablecoin operation:

```bash
ROLE_NAME=FREEZER ROLE_RECIPIENT="$(cast wallet address --private-key "$PRIVATE_KEY")" npm run step:02
```

Then freeze the account:

```bash
cast send "$TOKEN_ADDRESS" \
  "freeze(address)" "$ALICE_ADDRESS" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Transfers from a frozen account now revert:

```bash
cast send "$TOKEN_ADDRESS" \
  "transfer(address,uint256)" "$BOB_ADDRESS" 100000000 \
  --private-key "$ALICE_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Unfreeze so the rest of the walkthrough can continue:

```bash
cast send "$TOKEN_ADDRESS" \
  "unfreeze(address)" "$ALICE_ADDRESS" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Takeaway: freeze still exists as a normal stablecoin capability. The token keeps the asset-specific frozen-account state it enforces. ACE controls who may call `freeze` and `unfreeze`.

## Act 2: Add a blacklist without touching your contract

Now add a new compliance rule after deployment.

This is also the custom-policy moment. The sanctions policy in this repo is not a built-in ACE policy. That is the point. If the built-in library does not exactly match your use case, you can write your own policy with the same interface and attach it the same way.

### Step 5. Deploy and attach the sanctions policy

```bash
npm run step:04
```

Script: [script/04_AddSanctionsPolicy.s.sol](script/04_AddSanctionsPolicy.s.sol)

This deploys:

* `ERC20TransferExtractor`
* `SanctionsList`
* `SanctionsPolicy`

Then it attaches the custom sanctions policy to:

* `transfer`
* `transferFrom`

The policy checks both `from` and `to`, so it behaves like a real bidirectional blacklist rather than a recipient-only demo.

At the end, the script prints one paste-ready block of `export ...` commands for the new sanctions-related addresses. Copy that block into the same shell before moving to step 6.

### Step 6. Block an address

```bash
npm run step:05
```

Script: [script/05_BlockAddress.s.sol](script/05_BlockAddress.s.sol)

This adds `SANCTIONED_ADDRESS` to the sanctions list.

The script reprints a paste-ready export block for the sanctions list and sanctioned address so the next commands can be run from the same shell without retyping values.

### Step 7. Live proof

First make sure the sanctioned wallet has tokens:

```bash
cast send "$TOKEN_ADDRESS" \
  "mint(address,uint256)" "$SANCTIONED_ADDRESS" 2000000000 \
  --private-key "$MINTER_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Transfer to a sanctioned address reverts:

```bash
cast send "$TOKEN_ADDRESS" \
  "transfer(address,uint256)" "$SANCTIONED_ADDRESS" 100000000 \
  --private-key "$ALICE_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Approve a spender from the sanctioned account:

```bash
cast send "$TOKEN_ADDRESS" \
  "approve(address,uint256)" "$(cast wallet address --private-key "$PRIVATE_KEY")" 100000000 \
  --private-key "$SANCTIONED_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Transfer from the sanctioned account reverts:

```bash
cast send "$TOKEN_ADDRESS" \
  "transferFrom(address,address,uint256)" "$SANCTIONED_ADDRESS" "$BOB_ADDRESS" 100000000 \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Remove the address from the sanctions list:

```bash
cast send "$SANCTIONS_LIST_ADDRESS" \
  "remove(address)" "$SANCTIONED_ADDRESS" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Transfer succeeds again:

```bash
cast send "$TOKEN_ADDRESS" \
  "transfer(address,uint256)" "$BOB_ADDRESS" 100000000 \
  --private-key "$ALICE_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Takeaway: blacklisting was added after deployment with zero changes to the token contract.

The custom policy itself is small and only implements the ACE `run()` pattern. That is the broader lesson of Act 2: the `PolicyEngine` does not care whether a policy is built-in, custom, or third-party. Same interface, same attach mechanism.

## Act 3: The future-proof moment

Now add a requirement you do not need yet, but could absolutely need later.

This is the “future-proof” moment: the token contract stays unchanged, and new compliance behavior arrives as one more policy attachment.

### Step 8. Attach a transfer cap

```bash
npm run step:06
```

Script: [script/06_AddTransferLimit.s.sol](script/06_AddTransferLimit.s.sol)

This deploys `MaxPolicy`, configures a `10,000` token cap, and attaches it to:

* `transfer`
* `transferFrom`

At the end, the script prints a paste-ready export block for `MAX_POLICY_ADDRESS`.

### Step 9. Live proof

Transfer `5,000` succeeds:

```bash
cast send "$TOKEN_ADDRESS" \
  "transfer(address,uint256)" "$BOB_ADDRESS" 5000000000 \
  --private-key "$ALICE_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Transfer `15,000` reverts:

```bash
cast send "$TOKEN_ADDRESS" \
  "transfer(address,uint256)" "$BOB_ADDRESS" 15000000000 \
  --private-key "$ALICE_PRIVATE_KEY" \
  --rpc-url "$RPC_URL"
```

Takeaway: no token upgrade, no redeploy, no new audit of the token. Just a new policy deployment and attachment.

That is the future-proof claim in one terminal session: when requirements change, the token stays put.

## Running on a public testnet

Once you have run the full walkthrough locally on Anvil, the same six scripts run unchanged on any of the testnets pre-wired in `foundry.toml` and `.env.example`:

| Network          | foundry.toml profile | RPC env var                    |
| ---------------- | -------------------- | ------------------------------ |
| Ethereum Sepolia | `ethereumSepolia`    | `ETHEREUM_SEPOLIA_RPC_URL`     |
| Arbitrum Sepolia | `arbitrumSepolia`    | `ARBITRUM_SEPOLIA_RPC_URL`     |
| Base Sepolia     | `baseSepolia`        | `BASE_SEPOLIA_RPC_URL`         |
| OP Sepolia       | `optimismSepolia`    | `OPTIMISM_SEPOLIA_RPC_URL`     |
| Avalanche Fuji   | `avalancheFuji`      | `AVALANCHE_FUJI_RPC_URL`       |

To switch from Anvil to a public testnet:

1. Set the matching `*_RPC_URL` in your `.env` and re-`source` it.
2. Replace `PRIVATE_KEY` and `MINTER_PRIVATE_KEY` with funded accounts you control.
3. Replace `MINTER_ADDRESS`, `ALICE_ADDRESS`, `BOB_ADDRESS`, and `SANCTIONED_ADDRESS` with real testnet wallets.
4. Run the six scripts in order. The deployed addresses are chain-specific, so re-export `POLICY_ENGINE_ADDRESS`, `TOKEN_ADDRESS`, and friends after each step before moving on.

The npm scripts target `$RPC_URL` for convenience. To target a specific named profile instead, call forge directly:

```bash
forge script script/01_Deploy.s.sol:DeployStarterKit \
  --rpc-url ethereumSepolia \
  --broadcast
```

`HelperConfig.s.sol` will pick the right `NetworkConfig` automatically based on `block.chainid` and the deployment scripts will log which network they target at the top of each run.

## Production best practices

This walkthrough is intentionally simple so the ACE pattern is easy to see. Before reusing any of this code on mainnet, treat the following as required reading:

- **Audit the deployment scripts and any custom policy you write.** ACE itself is audited upstream, but your `SanctionsList`/`SanctionsPolicy` or any custom policy you derive from this kit is your responsibility.
- **Use a multisig or governance contract as the owner of the PolicyEngine.** The owner can attach, detach, and reconfigure policies on protected functions — that is the most sensitive key in the system.
- **Never reuse Anvil dev keys outside Anvil.** The defaults in `.env.example` are publicly known. Replace every key and address before pointing the kit at a public RPC.
- **Pin your dependencies.** ACE is installed via the `@chainlink/ace` npm package and OpenZeppelin via npm at exact versions. Commit `package-lock.json` so the dependency graph is reproducible, and do not silently bump versions; review the diff first.
- **Verify the implementation contracts behind every proxy.** The walkthrough uses `ERC1967Proxy` for `PolicyEngine`, the token, and each policy — verify both the proxy and the implementation on the relevant block explorer.
- **Confirm policy attachments after every change.** Use `cast call` to read back `getPolicies(...)` from `PolicyEngine` before assuming a new attachment is live.
- **Plan upgrades around state.** `ACEStablecoin` stores `frozen` accounts locally; if you fork it, remember that any storage layout change requires a careful upgrade plan because the token sits behind a proxy.

## What else is possible

This starter kit shows the first three moments that matter most for a stablecoin team, and for many RWA teams at the start of a regulated-token rollout:

* replace hardcoded RBAC with ACE RBAC
* replace hardcoded pause logic with ACE pause
* add a blacklist after deployment without touching the token
* prove you can add a brand new rule later without touching the token

That is the entry point, not the limit.

### 1. Built-in policy library

ACE already ships with a broader library of policies you can deploy and attach with the same pattern used in this repo:

* `VolumePolicy` for cumulative daily or weekly transfer limits
* `VolumeRatePolicy` for rate-limited volume and throttling
* `IntervalPolicy` for time-based trading windows, lock-up periods, and other transfer windows common in RWA programs
* `SecureMintPolicy` for more controlled mint workflows
* `OnlyOwnerPolicy`, `OnlyAuthorizedSenderPolicy`, `BypassPolicy`, `AllowPolicy`, and `RejectPolicy` for simpler routing and control patterns

RWA teams often start with this same RBAC + pause + blacklist setup, then layer on KYC requirements and trading restrictions as the program matures. That progression is exactly what this demo shows. This repo uses `RoleBasedAccessControlPolicy`, `PausePolicy`, and `MaxPolicy` because they map directly to what stablecoin and early-stage regulated-token teams already build today. The broader library is here: [ACE policy-management package](https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/policy-management/src/policies).

### 2. Custom policies

If the built-in library does not cover your exact use case, write your own policy.

[src/policies/SanctionsPolicy.sol](src/policies/SanctionsPolicy.sol) is the example in this repo. It implements one `run()` function, gets attached through the same `PolicyEngine`, and immediately becomes part of the token’s enforcement stack. The engine does not care whether a policy is built-in, custom, or written by a third party. Same interface, same attach mechanism.

### 3. Identity-gated policies

ACE is not limited to function-level rules. The broader stack supports identity-based validation as well.

That means you can gate flows on credentials tied to a cross-chain identity: KYC status, sanctions screening, accredited-investor checks, jurisdiction eligibility, or any other compliance credential your program needs. For RWA tokens, this is how you add investor accreditation or KYC gates without rewriting the asset contract. The important part is that this still uses the same mental model as everything else in this repo: attach a policy, keep the token contract unchanged.

### 4. Future possibilities

Whatever the ACE ecosystem adds later, new built-in policies, new credential types, new managed tooling, or support for new environments, your contract is already wired for it. That is the real value proposition: integrate once while the contract is still cheap to change, then keep adapting through configuration instead of upgrades.

## What’s next

You just proved the onchain pattern works.

If you want the same model with a managed control plane instead of raw scripts, that is what the ACE Platform is for: a dashboard, an API, managed policy deployment, identity operations, and reporting without having to build or operate the surrounding infrastructure yourself.

This repo is the self-serve proof that the contract pattern works. The platform is the next step when you want the operational experience around it.

If you want a walkthrough of that managed experience, use Chainlink’s contact flow here: [Talk to an expert](https://chain.link/contact).

## Resources

- [Chainlink ACE policy-management package](https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/policy-management)
- [Chainlink ACE documentation](https://docs.chain.link/)
- [OpenZeppelin upgradeable contracts](https://docs.openzeppelin.com/contracts/5.x/upgradeable)
- [Foundry book](https://book.getfoundry.sh/)
- Sibling Foundry starter kits: [foundry-starter-kit](https://github.com/smartcontractkit/foundry-starter-kit), [ccip-starter-kit-foundry](https://github.com/smartcontractkit/ccip-starter-kit-foundry)

## License

This repository is licensed under the [Business Source License 1.1](./LICENSE) (BUSL-1.1), matching the upstream Chainlink ACE contracts it depends on. See [LICENSE](./LICENSE) for the exact terms and the change date.
