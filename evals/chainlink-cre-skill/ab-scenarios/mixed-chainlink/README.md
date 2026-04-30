# Mixed Chainlink A/B Scenarios

These prompts are a curated A/B scenario set for `chainlink-cre-skill`. They mix broad Chainlink architecture prompts with CRE-specific implementation prompts so the evaluator can see both where the skill helps and where it should stay proportional.

Run them with:

```text
Run an agent A/B test for chainlink-cre-skill using mixed-chainlink
```

Expected historical pattern from manual testing:

- CRE workflow and deployment prompts should favor the skill response.
- Multi-service Chainlink app prompts often favor the skill when concrete integration details are useful.
- Broad architecture prompts may tie when CRE is optional or tangential.
