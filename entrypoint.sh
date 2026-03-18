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

getset_run_id() {
    local node_bin="$1"
    run_id=$("$node_bin" admin latest-run-id | tail -n 1)
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
getset_run_id "$INPUT_CONTENDER_BIN_MAIN"
"$INPUT_CONTENDER_BIN_MAIN" report -f json
report_a_path="$HOME/.contender/reports/report-$run_id-$run_id.json"

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
getset_run_id "$contender_bin_pr"
"$contender_bin_pr" report -f json
report_b_path="$HOME/.contender/reports/report-$run_id-$run_id.json"

# kill PR node
echo "Killing PR node (PID $pr_pid)"
kill $pr_pid
wait $pr_pid 2>/dev/null || true
echo "PR node stopped."

# export reports to GH output for use in next steps
report_a=$(cat "$report_a_path")
report_b=$(cat "$report_b_path")
{
  echo 'reports_json<<EOF'
  printf '{"report_a": %s, "report_b": %s}\n' "$report_a" "$report_b"
  echo 'EOF'
} >> "$GITHUB_OUTPUT"
