# Mini Savings Account

My implementation of a Mini Savings Account using Solidity and Foundry.
Current variant allows users to deposit their tokens and earn interest from them.
Users can also check their current rewards, claim their rewards or withdraw their tokens at any time.
Interest rate applied every second.

## Installation

To install with [**Foundry**](https://github.com/foundry-rs/foundry)

```sh
forge install
```

## Testing

```sh
forge test
```

## To-Do

- Implement a factory pattern, allowing the users to manage multiple accounts with different ERC20 tokens.

## Decisions

- It's not a time deposit account
- Version 1 uses 2 separate tokens for simplicity
