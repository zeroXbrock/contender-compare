#!/bin/bash
set -e
set -x

echo "contender_bin_main: $INPUT_CONTENDER_BIN_MAIN"
echo "node_bin_main: $INPUT_NODE_BIN_MAIN"
echo "node_args_main: $INPUT_NODE_ARGS_MAIN"
echo "node_bin_pr: $INPUT_NODE_BIN_PR"
echo "node_args_pr: $INPUT_NODE_ARGS_PR"
echo "rpc_main: $INPUT_RPC_MAIN"
echo "rpc_pr: $INPUT_RPC_PR"

# Set default CONTENDER_SPAM_ARGS if not already set
if [ -z "$CONTENDER_SPAM_ARGS" ]; then
    CONTENDER_SPAM_ARGS='--tps 100 -d 5 fill-block'
fi
echo "contender spam args: '$CONTENDER_SPAM_ARGS'"

# assign alternate contender bin if given, otherwise use same contender for both runs
if [ -z "$INPUT_CONTENDER_BIN_PR" ]; then
    contender_bin_pr="$INPUT_CONTENDER_BIN_MAIN"
else
    contender_bin_pr="$INPUT_CONTENDER_BIN_PR"
fi

# start a node and get its PID
start_node() {
    local bin="$1"
    local args="$2"
    echo "Starting node: $bin $args"
    "$bin" $args &
    node_pid=$!
}

# run main node
start_node "$INPUT_NODE_BIN_MAIN" "$INPUT_NODE_ARGS_MAIN"
main_pid=$node_pid
echo "Started main node with PID $main_pid"
sleep 5  # Give node time to start

# spam main node w/ contender
echo "Running contender against main node..."
"$INPUT_CONTENDER_BIN_MAIN" spam -r "$INPUT_RPC_MAIN" $CONTENDER_SPAM_ARGS

# generate A report
run_id=$("$INPUT_CONTENDER_BIN_MAIN" admin latest-run-id)
"$INPUT_CONTENDER_BIN_MAIN" report -f json
report_a="$HOME/.contender/reports/report-$run_id-$run_id.json"

# kill main node
echo "Killing main node (PID $main_pid)"
kill $main_pid
wait $main_pid 2>/dev/null || true
echo "Main node stopped."

# run PR node
start_node "$INPUT_NODE_BIN_PR" "$INPUT_NODE_ARGS_PR"
pr_pid=$node_pid
echo "Started PR node with PID $pr_pid"
sleep 5  # Give node time to start

# spam PR node w/ contender
echo "Running contender against PR node..."
"$contender_bin_pr" spam -r "$INPUT_RPC_PR" $CONTENDER_SPAM_ARGS

# generate B report
run_id=$("$contender_bin_pr" admin latest-run-id)
"$contender_bin_pr" report -f json
report_b="$HOME/.contender/reports/report-$run_id-$run_id.json"

# kill PR node
echo "Killing PR node (PID $pr_pid)"
kill $pr_pid
wait $pr_pid 2>/dev/null || true
echo "PR node stopped."

# TODO: post report summaries in PR
