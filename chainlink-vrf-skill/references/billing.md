# VRF v2.5 Billing

## Premium Percentages

VRF v2.5 charges a premium on top of the base gas cost:

| Payment Token | Premium (Ethereum Mainnet) |
|---|---|
| LINK | 20% |
| Native token (ETH, MATIC, etc.) | 24% |

Native token payment carries a slightly higher premium than LINK. If cost efficiency matters, pay in LINK.

Note: Premium percentages may differ on other networks. Check https://docs.chain.link/vrf/v2-5/billing for network-specific values.

**Official billing docs:** https://docs.chain.link/vrf/v2-5/billing

## Billing Timing

### Subscription Method
Billing is **post-fulfillment**. The actual gas consumed during the callback is measured and deducted from the subscription balance after `fulfillRandomWords` completes. You are charged for gas actually used, not an estimate.

### Direct Funding Method
Billing is **upfront**. The cost is estimated at request time and charged when `requestRandomWords` is called. The contract must hold sufficient balance before the call, or it will revert.

## Cost Formula

### Subscription
```
total cost = gas_price × (verification_gas + callback_gas_used) × ((100 + premium%) / 100)
```

### Direct Funding
```
total cost = gas_price × (
    coordinator_overhead_gas
    + callback_gas_limit
    + wrapper_overhead_gas
    + (coordinator_overhead_per_word × num_words)
) × ((100 + premium%) / 100)
```

Where `callback_gas_limit` is the value you set — you pay for the full limit even if your callback uses less.

## Choosing LINK vs Native Token

**Choose LINK when:**
- You want the lower 20% premium.
- You already hold LINK.
- You're using the subscription method and want one funding token for all subscriptions.

**Choose native token when:**
- You don't want to source LINK.
- The per-request premium difference is acceptable for your use case.
- You're using direct funding and the contract naturally holds ETH.

Per-request payment method is controlled by the `nativePayment` flag in `extraArgs` (subscription) or the `requestRandomnessPayInNative` function (direct funding). Subscriptions must be funded with the corresponding token.

## Funding a Subscription

**With LINK (ERC-677 transferAndCall):**
```solidity
// Programmatic funding
LINK.transferAndCall(
    coordinatorAddress,
    linkAmount,
    abi.encode(subscriptionId)
);
```

Or fund via the UI at https://vrf.chain.link.

**With native tokens:**
```solidity
coordinator.fundSubscriptionWithNative{value: amount}(subscriptionId);
```

## Withdrawal from Subscription

```solidity
// Withdraw LINK
coordinator.cancelSubscription(subscriptionId, receivingAddress);

// Or just withdraw excess without cancelling — use the VRF UI
```

## Minimum Balance

The coordinator requires a minimum balance buffer before processing requests to handle gas price volatility. If your subscription balance drops below the minimum:
- New requests will revert.
- In-flight requests may not be fulfilled.

Keep a buffer above the minimum. The VRF UI shows the current minimum at https://vrf.chain.link.

## PegSwap: Polygon and BNB Chain

On **Polygon** and **BNB Chain**, the LINK token from the canonical bridge is **not ERC-677 compatible**. You must convert it to ERC-677 LINK using PegSwap before it can be used to fund a VRF subscription or direct-funding contract.

- PegSwap: https://pegswap.chain.link
- Convert bridged LINK (ERC-20) → native LINK (ERC-677) before funding.

This only applies to bridge-sourced LINK. LINK purchased directly on these chains is already ERC-677.

## Typical Costs (Approximate, Sepolia Testnet)

| Method | Token | ~Cost per Request |
|---|---|---|
| Direct funding | LINK | ~0.877 LINK |
| Direct funding | Native (ETH) | ~0.001 ETH |

Mainnet costs are higher due to gas prices. Always estimate before deploying to mainnet.
