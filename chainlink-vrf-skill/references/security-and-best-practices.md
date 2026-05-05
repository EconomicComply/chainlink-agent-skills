# VRF v2.5 Security and Best Practices

**Official security considerations:** https://docs.chain.link/vrf/v2-5/security

## Bias Resistance

Chainlink VRF is designed to be tamper-proof and bias-resistant, but consumer contracts can introduce bias through poor design.

### Do Not Allow Re-Requesting

Once a request is made, do not allow re-requesting before fulfillment. A malicious user could observe the pending random value, cancel, and retry until a favorable value appears.

```solidity
// BAD — user can cancel and retry
function rollDie() external {
    if (pendingRequest) {
        cancelRequest(); // allows bias
    }
    pendingRequest = true;
    requestRandomWords(false);
}

// GOOD — one pending request per user/game at a time, no cancellation
function rollDie() external {
    require(!s_requests[lastRequestId].exists || s_requests[lastRequestId].fulfilled, "request pending");
    requestRandomWords(false);
}
```

### Commit-Reveal Pattern for Mappings

Do not expose the mapping between request IDs and user actions before fulfillment. If an attacker can read which request ID maps to their game, they might time actions around fulfillment.

```solidity
// BETTER — store the committer's address in the request
mapping(uint256 requestId => address player) private s_requestToPlayer;

function playGame() external {
    uint256 requestId = requestRandomWords(false);
    s_requestToPlayer[requestId] = msg.sender;
}
```

## Gas Limit Sizing

**Always test `callbackGasLimit` on a testnet before mainnet.**

The callback gas limit must cover the entire `fulfillRandomWords` execution. If it's too low, the callback reverts and randomness is lost — you cannot re-request the same randomness.

Estimation guide:
- Storage writes: ~20,000 gas each
- Events: ~375 gas + 8 gas per byte of data
- External calls: add 2,300 gas minimum per call

Add a 20–30% buffer above your measured usage. Use `eth_estimateGas` or Foundry's `--gas-report` to measure.

Maximum allowed: 2,500,000 gas.

## Request Lifecycle and Pending State

Track request state explicitly. A request that never gets fulfilled (due to insufficient subscription balance, coordinator issues, or gas too low) leaves your contract in a broken state if you don't handle it.

```solidity
enum RequestState { Nonexistent, Pending, Fulfilled, Failed }
mapping(uint256 => RequestState) public requestState;
```

Do not gate critical functionality solely on randomness delivery — have a timeout or admin escape hatch for stuck requests.

## Never Use Block Randomness as Fallback

Do not fall back to `block.prevrandao`, `block.difficulty`, `blockhash`, `block.timestamp`, or any combination of these as randomness when VRF is unavailable. These are manipulable by validators and provide no security guarantees.

```solidity
// NEVER DO THIS
uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));

// NEVER DO THIS either
uint256 randomValue = uint256(blockhash(block.number - 1));
```

If randomness isn't available, wait or revert — don't substitute insecure alternatives.

## Access Control on requestRandomWords

Restrict who can trigger randomness requests. A public `requestRandomWords` lets anyone drain your subscription or flood your contract with pending requests.

```solidity
// Restrict to owner or specific roles
function requestRandomWords(bool enableNativePayment) external onlyOwner returns (uint256) { ... }

// Or with role-based access
function requestRandomWords(bool enableNativePayment) external onlyRole(GAME_MANAGER_ROLE) returns (uint256) { ... }
```

## Subscription Balance Management

For subscription-based consumers:
- Monitor subscription balance via the VRF UI or by subscribing to `SubscriptionFunded` events.
- Set up alerting when balance drops below 2× the average request cost.
- Do not let the balance reach zero while requests are in-flight — unfulfilled requests cannot be retried with the same randomness.

## Coordinator Address Verification

Always verify the coordinator address you pass to the constructor matches the network you're deploying to. A wrong coordinator means your `fulfillRandomWords` callback will never be called.

```solidity
// Constructor should validate the coordinator is set
constructor(address coordinatorAddress, uint256 subscriptionId)
    VRFConsumerBaseV2Plus(coordinatorAddress) {
    require(coordinatorAddress != address(0), "invalid coordinator");
    s_subscriptionId = subscriptionId;
}
```

## Production Checklist

Before mainnet deployment:

- [ ] Tested on a testnet with real VRF fulfillments end-to-end
- [ ] `callbackGasLimit` measured and buffered on testnet
- [ ] `requestConfirmations` set appropriately for the value at risk (20+ for high-value lotteries)
- [ ] No re-requesting or cancellation allowed after a request is made
- [ ] Subscription balance monitored and alerting configured
- [ ] VRF coordinator address verified against supported-networks.md
- [ ] No fallback to block-based randomness
- [ ] Security audit completed by an independent auditor

This example code is **unaudited** and provided for educational purposes only. Do not use it in production without a thorough security review.
