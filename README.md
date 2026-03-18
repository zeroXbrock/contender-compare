# Contender Compare GitHub Action

This action runs [contender](https://github.com/flashbots/contender) against two user-specified node binaries.

> *Note: User is responsible for building node binaries before running this action.*

## Inputs

| Input | Description | Required | Default |
|-------|-------------|:--------:|---------|
| `contender_bin_main` | Path to the contender binary. | No | Downloads latest release |
| `contender_bin_pr` | Alternate contender binary; used for testing contender itself. | No | Same as `contender_bin_main` |
| `contender_spam_args` | Raw args to pass to `contender spam`. | No | `--tps 100 -d 5 erc20` |
| `node_bin_main` | Path to the main branch node binary. | **Yes** | |
| `node_args_main` | Arguments to pass to the main branch node binary. | No | |
| `node_bin_pr` | Path to the PR branch node binary. | **Yes** | |
| `node_args_pr` | Arguments to pass to the PR branch node binary. | No | |
| `rpc_main` | RPC URL of the main branch's EL node. | No | `http://localhost:8545` |
| `rpc_pr` | RPC URL of the PR branch's EL node. | No | `http://localhost:9545` |

## Example usage

```yaml
jobs:
  contender-compare:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build main and PR binaries
        run: |
          # build your node's binaries & set paths here
          mv reth_main_x86-64 ./bin/reth-main
          mv reth_v1.11.0_x86-64 ./bin/reth-dev

      - name: Run contender compare
        uses: flashbots/contender-compare
        with:
          node_bin_main: ./bin/reth-main
          node_args_main: node --http
          node_bin_pr: ./bin/reth-dev
          node_args_pr: node --http --http.port 9545
```
