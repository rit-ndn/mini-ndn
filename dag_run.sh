#!/bin/bash

#----- THIS ONLY NEEDS TO BE RUN ONCE --------------------
#cd ~/mini-ndn/dl/ndn-cxx
#./waf clean
#./waf
#sudo ./waf install
#---------------------------------------------------------

set -e

MININDN_HOME="$HOME/mini-ndn"

script_dir="$MININDN_HOME/examples"
scripts=(
# 4 DAG
#"cabeee-4dag-orchestratorA.py"
#"cabeee-4dag-orchestratorB.py"
"cabeee-4dag.py"
# 20 Linear
#"cabeee-20node-linear-orchestratorA.py"
#"cabeee-20node-linear-orchestratorB.py"
#"cabeee-20node-linear.py"
# 20 Parallel
#"cabeee-20node-parallel-orchestratorA.py"
#"cabeee-20node-parallel-orchestratorB.py"
#"cabeee-20node-parallel.py"
# 20 Sensor (Parallel)
#"cabeee-20sensor-parallel-orchestratorA.py"
#"cabeee-20sensor-parallel-orchestratorB.py"
#"cabeee-20sensor-parallel.py"
# 8 DAG
#"cabeee-8dag-orchestratorA.py"
#"cabeee-8dag-orchestratorB.py"
#"cabeee-8dag.py"
# 8 DAG w/ caching
#"cabeee-8dag-caching-orchestratorA.py"
#"cabeee-8dag-caching-orchestratorB.py"
#"cabeee-8dag-caching.py"
# Misc
#"cabeee-chunks.py"
)

example_log="$MININDN_HOME/example.log"
consumer_log="/tmp/minindn/user/cabeee_consumer.log"
csv_out="$MININDN_HOME/perf-results.csv"
header="Example, Interest Packets Generated, Data Packets Generated, Interest Packets Transmitted, Data Packets Transmitted, Service Latency, Final Result, Time, mini-ndn commit, ndn-cxx commit, NFD commit, NLSR commit"

cp "$csv_out" "$csv_out.bak"

if [ ! -f "$csv_out" ]; then
	echo "$header" > "$csv_out"
elif ! grep -q -F "$header" "$csv_out"; then
	echo "Overwriting csv..."
	mv "$csv_out" "$csv_out.bak"
	echo "$header" > "$csv_out"
fi

for script in "${scripts[@]}"
do
	now="$(date -Iseconds)"

	minindn_hash="$(git -C "$MININDN_HOME" rev-parse HEAD)"
	ndncxx_hash="$(git -C "$MININDN_HOME/dl/ndn-cxx" rev-parse HEAD)"
	nfd_hash="$(git -C "$MININDN_HOME/dl/NFD" rev-parse HEAD)"
	nlsr_hash="$(git -C "$MININDN_HOME/dl/NLSR" rev-parse HEAD)"

	# these sed scripts depend on the order in which the logs are printed

	# shellcheck disable=SC2024
        sudo -E python "$script_dir/$script" > "$example_log"
	packets=$(sed -n \
		-e 's/^Interest Packets Generated: \([0-9]*\) interests$/\1,/p' \
		-e 's/^Data Packets Generated: \([0-9]*\) data$/\1,/p' \
		-e 's/^Interest Packets Transmitted: \([0-9]*\) interests$/\1,/p' \
		-e 's/^Data Packets Transmitted: \([0-9]*\) data/\1,/p' \
		"$example_log" \
		| tr -d '\n' \
	)

	interest_gen="$(echo "$packets" | cut -d',' -f1)"
	data_gen="$(echo "$packets" | cut -d',' -f2)"
	interest_trans="$(echo "$packets" | cut -d',' -f3)"
	data_trans="$(echo "$packets" | cut -d',' -f4)"

	consumer_parse=$(sed -n \
		-e 's/^\s*The final answer is: \([0-9]*\)$/\1,/p' \
		-e 's/^\s*Service Latency: \([0-9\.]*\) seconds.$/\1,/p' \
		"$consumer_log" \
		| tr -d '\n' \
	)

	result="$(echo "$consumer_parse" | cut -d',' -f1)"
	latency="$(echo "$consumer_parse" | cut -d',' -f2)"

	row="$script, $interest_gen, $data_gen, $interest_trans, $data_trans, $latency, $result, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"

	# WARN: $script is NOT escaped, so don't use any fancy characters
	# the dot in the file extension technically matches any character, but this shouldn't matter
	# basically this is fragile, don't be weird with these strings
	line_num="$(grep -n -F "$script," "$csv_out" | cut -d: -f1 | head -1)"
	if [ -n "$line_num" ]; then
		sed --in-place -e "${line_num}c\\$row" "$csv_out"
	else
		echo "$row" >> "$csv_out"
	fi
done
