# Contender Compare GitHub Action

This action runs [contender](https://github.com/flashbots/contender) against two user-specified node binaries.

## Inputs
- `contender_bin`: Path to the contender binary (required)
- `binary_main`: Path to the main branch node binary (required)
- `binary_pr`: Path to the PR branch node binary (required)

## Example usage
```yaml
jobs:
  contender-compare:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build main and PR binaries
        run: |
          # User builds binaries here
          echo "Build your binaries and set paths"
      - name: Run contender compare
        uses: ./contender-compare
        with:
          contender_bin: ./path/to/contender
          binary_main: ./path/to/main-binary
          binary_pr: ./path/to/pr-binary
```

## Notes
- User is responsible for building the contender binary and node binaries before running this action.
- Pass the path to the built contender binary via `contender_bin`.
- Requires Rust toolchain for contender build (not needed in the action itself).
