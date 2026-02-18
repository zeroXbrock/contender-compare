#!/bin/bash
set -e


# Inputs
contender_bin="$1"
node_main_bin="$2"
node_main_args="$3"
node_pr_bin="$4"
node_pr_args="$5"
rpc_main="$6"
rpc_pr="$7"

# Helper to start a node and get its PID
start_node() {
	local bin="$1"
	local args="$2"
	"$bin" $args &
	echo $!
}

# Run contender against main node
main_pid=$(start_node "$node_main_bin" "$node_main_args")
sleep 5  # Give node time to start
"$contender_bin" spam fill-block -r "$rpc_main" --tps 100 -d 5
kill $main_pid
wait $main_pid 2>/dev/null || true

# Run contender against PR node
pr_pid=$(start_node "$node_pr_bin" "$node_pr_args")
sleep 5  # Give node time to start
"$contender_bin" spam fill-block -r "$rpc_pr" --tps 100 -d 5
kill $pr_pid
wait $pr_pid 2>/dev/null || true

# Optionally, user can provide custom scenarios or campaigns
# See docs/examples.md and docs/campaigns.md in contender repo
