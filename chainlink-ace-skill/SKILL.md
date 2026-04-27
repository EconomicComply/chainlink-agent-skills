---
name: chainlink-ace-skill
description: "Handle Chainlink ACE (Automated Compliance Engine) work using the public smartcontractkit/chainlink-ace repository: audited ACE core contracts, Policy Management, PolicyEngine, PolicyProtected, policy chains, custom policies, extractors, mappers, Cross-Chain Identity, CCIDs, credential registries, KYC/AML credentials, regulated tokens, ERC-20 and ERC-3643 compliance token examples, Foundry setup, upgrade guidance, and BUSL licensing. Use this skill whenever the user mentions ACE, Automated Compliance Engine, chainlink-ace, Chainlink compliance, policy enforcement, PolicyEngine, PolicyProtected, CCID, credential registries, KYC/AML credentials, sanctions screening, regulated tokens, ERC-3643 compliance, or onchain compliance rules, even if they do not explicitly say 'ACE'."
license: MIT
compatibility: Designed for AI agents that implement https://agentskills.io/specification, including Claude Code, Cursor Composer, and Codex-style workflows.
allowed-tools: Read WebFetch Write Edit Bash
metadata:
  purpose: Chainlink ACE core contracts developer onboarding, compliance architecture, and reference guidance
  version: "0.0.2"
---

# Chainlink ACE Skill

## Overview

Help users build with the public Chainlink ACE core contracts in `smartcontractkit/chainlink-ace`. ACE provides modular onchain policy enforcement and cross-chain identity contracts for EVM applications. Treat the GitHub repository as the source of truth for this skill.

## Progressive Disclosure

1. Keep this file as the default guide.
2. Read [references/getting-started-and-scope.md](references/getting-started-and-scope.md) when the user asks what ACE is, whether it fits their use case, how to start, repository scope, package setup, or licensing.
3. Read [references/onchain-contracts.md](references/onchain-contracts.md) when the user mentions the `chainlink-ace` GitHub repo, self-deployment, Foundry, audited contracts, custom policies/extractors/mappers, upgrade an existing contract, or BUSL/prod licensing.
4. Read [references/architecture.md](references/architecture.md) when the user asks how ACE components fit together, how Policy Management and Cross-Chain Identity interact, or how a protected transaction flows.
5. Read [references/policy-management.md](references/policy-management.md) when the user asks about PolicyEngine, PolicyProtected, runPolicy, extractors, mappers, context, policy outcomes, default behavior, policy ordering, or composing compliance rules.
6. Read [references/policy-library.md](references/policy-library.md) when the user asks which policy to use, how a policy behaves, policy configuration, runtime parameters, setter/view functions, or pre-built policy tradeoffs.
7. Read [references/cross-chain-identity.md](references/cross-chain-identity.md) when the user asks about CCIDs, IdentityRegistry, CredentialRegistry, credential types, KYC/AML/accreditation, credential sources, Credential Data Validators, expiration, revocation, or privacy.
8. Read [references/contracts-and-source.md](references/contracts-and-source.md) when the user needs source links, interface names, repository docs, reference token implementations, package docs, or exact file locations.
9. Read [references/official-sources.md](references/official-sources.md) when the answer depends on current repo facts, source code, package scripts, licensing, interfaces, or docs paths.
10. Read [assets/ace-docs-index.md](assets/ace-docs-index.md) only when you need a map of public repository documentation covered by this skill.
11. Do not load reference files speculatively.

## Routing

1. Use the public `smartcontractkit/chainlink-ace` repository as the source of truth.
2. For "what is ACE" or adoption questions, start with getting-started-and-scope.md.
3. For implementation design, start with onchain-contracts.md, then route to policy-management.md, policy-library.md, or cross-chain-identity.md as needed.
4. For "which policies do I need" questions, use policy-library.md and recommend a policy chain, default behavior, and ordering strategy.
5. For identity or credential requirements, use cross-chain-identity.md. ACE's public contracts support Credential Data Validator patterns; do not claim credential checks are attestation-only.
6. Ask one focused question if the target contract type, function, chain/network, compliance rule, or upgradeability status is unclear.
7. Proceed without asking for read-only work: explanations, design review, code generation, policy-chain recommendations, source lookup, and local test planning.
8. Do not assume this skill is the only capability available. Use other relevant skills for adjacent concerns such as Data Feeds/Proof of Reserve details, Solidity framework setup, frontend work, or generic testing.

## Public Repo Defaults

1. The `smartcontractkit/chainlink-ace` repository contains ACE core contracts under BUSL-1.1.
2. The package metadata identifies the package as `@chainlink/ace`.
3. The repository is Foundry-based and includes scripts such as `pnpm build`, `pnpm test`, `pnpm lint`, and token deployment scripts.
4. The core packages are `packages/policy-management`, `packages/cross-chain-identity`, and `packages/tokens`.
5. Policy Management can be used standalone. Cross-Chain Identity depends on Policy Management.
6. Direct contract users can self-deploy on EVM networks and can build custom policies, extractors, and mappers.
7. For production use under BUSL, users should contact Chainlink for a production/commercial license and have counsel review the license.
8. Do not mention non-repository ACE product surfaces, access programs, APIs, or documentation.

## Safety Guardrails

1. Never execute or guide an agent to execute onchain writes without explicit user approval.
2. Do not refuse mainnet or production questions solely because they involve ACE. Instead, call out production licensing, security review, and explicit approval requirements.
3. Treat compliance design as high-impact guidance. Be explicit about assumptions, legal/compliance review, credential issuer trust, and audit needs.
4. Never advise storing PII onchain. Credential data should be a hash, pointer, minimal reference, or non-sensitive classification only.
5. For policy chains, explain terminal outcomes: `PolicyRejected` reverts, `Allowed` skips remaining policies, and `Continue` moves to the next policy or default behavior.
6. Prefer restrictive checks before permissive bypasses unless the user intentionally wants privileged addresses to skip all subsequent checks.
7. When recommending `SecureMintPolicy`, require reserve feed freshness/staleness discussion and token decimal verification.
8. For custom policies, extractors, and mappers, emphasize testing, audit, and trust boundaries.
9. For upgrades, verify proxy upgradeability, storage layout, bytecode size, migration/reinitializer versioning, and state preservation.

## Approval Protocol

Before any ACE action that deploys, configures, upgrades, registers, issues, revokes, attaches, reorders, or otherwise writes onchain state, present a short preflight summary:

```text
Proposed ACE operation:
- Action: ...
- Network: ...
- Target contract: ...
- PolicyEngine: ...
- Function selector(s): ...
- Policies/extractors/mappers/registries/credentials affected: ...
- Sender or admin account: ...
- License/production note: ...
- Expected effect: ...

Do you want me to execute this?
```

Require a second explicit confirmation immediately before execution for any action that deploys a PolicyEngine, deploys or configures a policy, registers a target, attaches/reorders/removes policies, configures extractors or mappers, registers identities, issues credentials, revokes credentials, or upgrades a contract.

## Documentation Access

This skill is based on the public `smartcontractkit/chainlink-ace` repository. Use repository docs only for ACE-specific source material.

1. For stable concepts, use the embedded reference files.
2. For current repo details, fetch files from `https://github.com/smartcontractkit/chainlink-ace` or raw GitHub URLs listed in [references/official-sources.md](references/official-sources.md).
3. If WebFetch is available, use it first. If it returns insufficient content, try `curl -L <github-or-raw-github-url>`.
4. If source fetching fails, tell the user which repository URL could not be retrieved and do not invent freshness-sensitive facts.

## Working Rules

1. Keep answers proportional. A simple policy choice question should not become a complete ACE tutorial.
2. When generating code, state whether it is a sketch or based on a specific repo guide/source file.
3. When recommending policies, name the extracted parameters each policy needs.
4. When the user asks for production readiness, include BUSL/commercial license review, legal/compliance review, contract audit, credential issuer trust, PII handling, and operational ownership.
