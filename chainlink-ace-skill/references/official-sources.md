# Official Sources

Use this file when an answer depends on current ACE repository facts, source code, package scripts, docs paths, or licensing.

## Freshness Policy

1. Use only the public `smartcontractkit/chainlink-ace` repository and raw GitHub files for ACE-specific source material.
2. Do not use non-repository ACE docs as source material for this skill.
3. Re-check repository source before providing exact function signatures, event schemas, package scripts, remappings, imports, or license details.
4. If live repository source conflicts with a bundled reference, prefer the live repository source and say that the repo has changed.
5. Cite the exact GitHub source used for freshness-sensitive answers.

## Repository

- Main repository: `https://github.com/smartcontractkit/chainlink-ace`
- Raw base: `https://raw.githubusercontent.com/smartcontractkit/chainlink-ace/main/`

## Top-Level Docs

| Topic | URL |
| --- | --- |
| Main README | `https://github.com/smartcontractkit/chainlink-ace/blob/main/README.md` |
| Getting Started | `https://github.com/smartcontractkit/chainlink-ace/blob/main/getting_started/GETTING_STARTED.md` |
| Advanced Getting Started | `https://github.com/smartcontractkit/chainlink-ace/blob/main/getting_started/advanced/GETTING_STARTED_ADVANCED.md` |
| Upgrade Guide | `https://github.com/smartcontractkit/chainlink-ace/blob/main/UPGRADE_GUIDE.md` |
| Glossary | `https://github.com/smartcontractkit/chainlink-ace/blob/main/Glossary.md` |
| License | `https://github.com/smartcontractkit/chainlink-ace/blob/main/LICENSE` |
| Package metadata | `https://github.com/smartcontractkit/chainlink-ace/blob/main/package.json` |
| Remappings | `https://github.com/smartcontractkit/chainlink-ace/blob/main/remappings.txt` |

## Policy Management

| Topic | URL |
| --- | --- |
| Package README | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/README.md` |
| Concepts | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/docs/CONCEPTS.md` |
| API Guide | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/docs/API_GUIDE.md` |
| API Reference | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/docs/API_REFERENCE.md` |
| Custom Policies Tutorial | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/docs/CUSTOM_POLICIES_TUTORIAL.md` |
| Policy Ordering Guide | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/docs/POLICY_ORDERING_GUIDE.md` |
| Security | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/docs/SECURITY.md` |
| Policies README | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/policy-management/src/policies/README.md` |
| Interfaces | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/policy-management/src/interfaces` |
| Core contracts | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/policy-management/src/core` |
| Extractors | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/policy-management/src/extractors` |
| Mappers | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/policy-management/src/mappers` |

## Cross-Chain Identity

| Topic | URL |
| --- | --- |
| Package README | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/README.md` |
| Concepts | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/docs/CONCEPTS.md` |
| API Guide | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/docs/API_GUIDE.md` |
| API Reference | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/docs/API_REFERENCE.md` |
| Credential Flow | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/docs/CREDENTIAL_FLOW.md` |
| Security | `https://github.com/smartcontractkit/chainlink-ace/blob/main/packages/cross-chain-identity/docs/SECURITY.md` |
| Interfaces | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/cross-chain-identity/src/interfaces` |

## Token Examples

| Topic | URL |
| --- | --- |
| Tokens package | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/tokens` |
| ERC-20 compliance token | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/tokens/erc-20` |
| ERC-3643 compliance token | `https://github.com/smartcontractkit/chainlink-ace/tree/main/packages/tokens/erc-3643` |
| Deploy scripts | `https://github.com/smartcontractkit/chainlink-ace/tree/main/script` |

## Practical Selection Rules

1. For repository overview and where to start, fetch the main README.
2. For new integrations, fetch the Getting Started guide and relevant package README.
3. For existing upgradeable contracts, fetch the Upgrade Guide.
4. For policy behavior, fetch `packages/policy-management/src/policies/README.md`.
5. For exact signatures, fetch the relevant Solidity interface/source file.
6. For identity and credentials, fetch Cross-Chain Identity package docs.
7. For production licensing, fetch `LICENSE` and tell the user to contact Chainlink and consult counsel.
