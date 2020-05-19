# Batch Token Performance Demo

A number of layer 2 scaling solutions have proposed various methods of enhancing the throughput of token transfers. A common element of these solutions is that an operator batches a set of transfers together.

There are two main areas of savings in any of these approaches:

1) Base tx cost: Every Ethereum transaction has a base cost of 21000 gas. Batching them amortizes this cost.

2) Signature verification: Normally each transfer requires a separate signature verification. Non-interactive rollup solutions (ZK-Rollup, BLS-Rollup) use cryptographic mechanisms to avoid having to check each transaction.

This repository implements a basic batch transfer token contract. My goal is to create a fair baseline for new token transfer scaling solutions to compare with, rather than comparing with standard ETH or ERC 20 transfers.

# Soft Confirmations

Recently the idea of using a centralized sequencer has been popularized in the context of optimistic rollups. The idea is that there is a single sequencer who can submit transactions for immediate processing by a contract. They can make promises about what transactions they will include in their next on-chain transaction and send these to their users. The sequencer is not bound by their promise, but can be slashed if they break it. Since the sequencer has unilateral control of what transactions are processed quickly, they can reorder and insert their own transactions at will. Concerns about censorship can be reduced by supplying a slow method for users to force their transactions to be processed.

I hope with this implementation to clarify to people that this design has nothing to do with optimistic rollup. It is an interesting area of the smart contract design space that can just as well be implemented in a standard layer 1 smart contract as demonstrated in this repo. In this example, there is no risk of frontrunning and so the downsides of the approach are limited.

Note that the sequencer must be trusted in order to accept their commitment to a batch of transactions before it has been secured by the layer 1 chain. There is no way to prevent the sequencer from refusing to honor a given batch commitment, and it may be that lying to users could be more valuable than the sequencer's deposit.

# Transaction Specification

Each transfer requires a 65 byte ECDSA signature as well as 32 bytes of data. The contract verifies the signature for each transfer, checks it is valid, and then executes it.

`Data = [sender(uint32) | destination(uint32) | nonce(uint32) | amount(uint64)]`

# Performance

To recreate performance numbers yourself, just launch ganache `ganache-cli` and run the test `truffle test`

## Pre Istanbul

Batch transfer of 100 used 2145601 gas

Used **21246.01 gas per transfer**

## Post Istanbul

Batch transfer of 100 used 1266365 gas

Used **12453.65 gas per transfer**
