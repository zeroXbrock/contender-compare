#!/bin/bash
set -e
set -x

# Inputs from environment variables
contender_bin="$INPUT_CONTENDER_BIN"
node_main_bin="$INPUT_BINARY_MAIN"
node_main_args="$INPUT_BINARY_MAIN_ARGS"
node_pr_bin="$INPUT_BINARY_PR"
node_pr_args="$INPUT_BINARY_PR_ARGS"
rpc_main="$INPUT_RPC_MAIN"
rpc_pr="$INPUT_RPC_PR"

echo "contender_bin: $contender_bin"
echo "node_main_bin: $node_main_bin"
echo "node_main_args: $node_main_args"
echo "node_pr_bin: $node_pr_bin"
echo "node_pr_args: $node_pr_args"
echo "rpc_main: $rpc_main"
echo "rpc_pr: $rpc_pr"

# Set default CONTENDER_SPAM_ARGS if not already set
if [ -z "$CONTENDER_SPAM_ARGS" ]; then
    CONTENDER_SPAM_ARGS='--tps 100 -d 5 fill-block'
fi
echo "contender spam args: '$CONTENDER_SPAM_ARGS'"

# assign alternate contender bin if given, otherwise use same contender for both runs
if [ -z "$INPUT_CONTENDER_BIN_PR" ]; then
	contender_bin_pr="$INPUT_CONTENDER_BIN"
else
	contender_bin_pr="$INPUT_CONTENDER_BIN_PR"
fi

# Helper to start a node and get its PID
start_node() {
    local bin="$1"
    local args="$2"
    echo "Starting node: $bin $args"
    "$bin" $args &
    node_pid=$!
}

# Run contender against main node
start_node "$node_main_bin" "$node_main_args"
main_pid=$node_pid
echo "Started main node with PID $main_pid"
sleep 5  # Give node time to start
echo "Running contender against main node..."
"$contender_bin" spam -r "$rpc_main" $CONTENDER_SPAM_ARGS
echo "Killing main node (PID $main_pid)"
kill $main_pid
wait $main_pid 2>/dev/null || true
echo "Main node stopped."

# Run contender against PR node
start_node "$node_pr_bin" "$node_pr_args"
pr_pid=$node_pid
echo "Started PR node with PID $pr_pid"
sleep 5  # Give node time to start
echo "Running contender against PR node..."
"$contender_bin_pr" spam -r "$rpc_pr" $CONTENDER_SPAM_ARGS
echo "Killing PR node (PID $pr_pid)"
kill $pr_pid
wait $pr_pid 2>/dev/null || true
echo "PR node stopped."
