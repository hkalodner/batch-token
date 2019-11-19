# Batch Token Performance Demo

A number of layer 2 scaling solutions have proposed various methods of enhancing the throughput of token transfers. A common element of these solutions is that an operator batches a set of transfers together.

There are two main areas of savings in any of these approaches:
	1) Base transaction cost: Every Ethereum transaction has a base cost of 21000 gas. Batching them together amortizes this cost.
	2) Signature verification: Normally each transfer requires an independent signature verification. Non-interactive rollup solutions (ZK-Rollup, BLS-Rollup) use cryptographic mechanisms to avoid having to do a check for each transaction.

This repository implements a basic batch transfer token contract. My goal is to create a fair baseline for new token transfer scaling solutions to compare with, rather than comparing with standard ETH or ERC 20 transfers.

# Transaction Specification

Each transfer requires a 65 byte ECDSA signature as well as 32 bytes of data. The contract verifies the signature for each transfer, checks it is valid, and then executes it.

`Data = [sender(uint32) | destination(uint32) | nonce(uint32) | amount(uint64)]`

# Performance

To recreate performance numbers yourself, just launch ganache `ganache-cli` and run the test `truffle test`

## Pre Istanbul

Batch transfer of 100 used 1133334 gas
Used 11123.34 gas per transfer

## Post Istanbul

Batch transfer of 100 used 1432198 gas
Used 14111.98 gas per transfer
