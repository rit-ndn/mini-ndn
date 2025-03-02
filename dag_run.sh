#!/bin/bash

#----- THIS ONLY NEEDS TO BE RUN ONCE --------------------
#cd ~/mini-ndn/dl/ndn-cxx
#./waf clean
#./waf
#sudo ./waf install
#---------------------------------------------------------

set -e


numSamples=20

MININDN_HOME="$HOME/mini-ndn"
NDNCXX_DIR="$HOME/mini-ndn/dl/ndn-cxx/run_scripts_hardware"
WORKFLOW_DIR="$NDNCXX_DIR/workflows"
TOPOLOGY_DIR="$NDNCXX_DIR/topologies"
CPM_DIR="$MININDN_HOME/dl/CPM"


script_dir="$MININDN_HOME/examples"

scripts=(
# 4 DAG
#"cabeee-4dag-orchestratorA.py"
#"cabeee-4dag-orchestratorB.py"
#"cabeee-4dag-nesco.py"
#"cabeee-4dag-nescoSCOPT.py"
# 8 DAG
#"cabeee-8dag-orchestratorA.py"
#"cabeee-8dag-orchestratorB.py"
#"cabeee-8dag-nesco.py"
#"cabeee-8dag-nescoSCOPT.py"
# 8 DAG w/ caching
#"cabeee-8dag-caching-orchestratorA.py"
#"cabeee-8dag-caching-orchestratorB.py"
#"cabeee-8dag-caching-nesco.py"
#"cabeee-8dag-caching-nescoSCOPT.py"
# 20 Sensor (new hosting using 3node topology)
#"cabeee-20sensor-orchestratorA.py"
#"cabeee-20sensor-orchestratorB.py"
#"cabeee-20sensor-nesco.py"
#"cabeee-20sensor-nescoSCOPT.py"
# 20 Linear (new hosting using 3node topology)
#"cabeee-20linear-orchestratorA.py"
#"cabeee-20linear-orchestratorB.py"
#"cabeee-20linear-nesco.py"
#"cabeee-20linear-nescoSCOPT.py"
# 20 Reuse (new hosting using 3node topology)
#"cabeee-20reuse-orchestratorA.py"
#"cabeee-20reuse-orchestratorB.py"
#"cabeee-20reuse-nesco.py"
#"cabeee-20reuse-nescoSCOPT.py"


# 20 Scrambled (new hosting using 3node topology)
#"cabeee-20scrambled-orchestratorA.py"
#"cabeee-20scrambled-orchestratorB.py"
#"cabeee-20scrambled-nesco.py"
#"cabeee-20scrambled-nescoSCOPT.py"
# 20 Parallel (new hosting using 3node topology)
#"cabeee-20parallel-orchestratorA.py"
#"cabeee-20parallel-orchestratorB.py"
#"cabeee-20parallel-nesco.py"
#"cabeee-20parallel-nescoSCOPT.py"
# 20-Node Linear
#"cabeee-20node-linear-orchestratorA.py"
#"cabeee-20node-linear-orchestratorB.py"
#"cabeee-20node-linear-nesco.py"
#"cabeee-20node-linear-nescoSCOPT.py"
# 20 Node Parallel
#"cabeee-20node-parallel-orchestratorA.py"
#"cabeee-20node-parallel-orchestratorB.py"
#"cabeee-20node-parallel-nesco.py"
#"cabeee-20node-parallel-nescoSCOPT.py"
# 20 Sensor (Parallel with 20 nodes and 20 sensors)
#"cabeee-20sensor-parallel-orchestratorA.py"
#"cabeee-20sensor-parallel-orchestratorB.py"
#"cabeee-20sensor-parallel-nesco.py"
#"cabeee-20sensor-parallel-nescoSCOPT.py"
# 20-Node Scrambled
#"cabeee-20node-scrambled-nesco.py"
#"cabeee-20node-scrambled-nescoSCOPT.py"
# Misc
#"cabeee-chunks.py"
)

declare -a scenarios=(
# 4 DAG
"cabeee-4dag-orchestratorA.py orchA 4dag.json 4dag.hosting topo-cabeee-3node.json"
"cabeee-4dag-orchestratorB.py orchB 4dag.json 4dag.hosting topo-cabeee-3node.json"
"cabeee-4dag-nesco.py nesco 4dag.json 4dag.hosting topo-cabeee-3node.json"
"cabeee-4dag-nescoSCOPT.py nescoSCOPT 4dag.json 4dag.hosting topo-cabeee-3node.json"
# 8 DAG
"cabeee-8dag-orchestratorA.py orchA 8dag.json 8dag.hosting topo-cabeee-3node.json"
"cabeee-8dag-orchestratorB.py orchB 8dag.json 8dag.hosting topo-cabeee-3node.json"
"cabeee-8dag-nesco.py nesco 8dag.json 8dag.hosting topo-cabeee-3node.json"
"cabeee-8dag-nescoSCOPT.py nescoSCOPT 8dag.json 8dag.hosting topo-cabeee-3node.json"
# 8 DAG w/ caching
"cabeee-8dag-caching-orchestratorA.py orchA 8dag.json 8dag.hosting topo-cabeee-3node.json"
"cabeee-8dag-caching-orchestratorB.py orchB 8dag.json 8dag.hosting topo-cabeee-3node.json"
"cabeee-8dag-caching-nesco.py nesco 8dag.json 8dag.hosting topo-cabeee-3node.json"
"cabeee-8dag-caching-nescoSCOPT.py nescoSCOPT 8dag.json 8dag.hosting topo-cabeee-3node.json"
# 20 Sensor (using 3node topology)
"cabeee-20sensor-orchestratorA.py orchA 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
"cabeee-20sensor-orchestratorB.py orchB 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
"cabeee-20sensor-nesco.py nesco 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
"cabeee-20sensor-nescoSCOPT.py nescoSCOPT 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
# 20 Linear (using 3node topology)
"cabeee-20linear-orchestratorA.py orchA 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
"cabeee-20linear-orchestratorB.py orchB 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
"cabeee-20linear-nesco.py nesco 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
"cabeee-20linear-nescoSCOPT.py nescoSCOPT 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
# 20 Reuse (using 3node topology)
"cabeee-20reuse-orchestratorA.py orchA 20-reuse.json 20-reuse-in3node.hosting topo-cabeee-3node.json"
"cabeee-20reuse-orchestratorB.py orchB 20-reuse.json 20-reuse-in3node.hosting topo-cabeee-3node.json"
"cabeee-20reuse-nesco.py nesco 20-reuse.json 20-reuse-in3node.hosting topo-cabeee-3node.json"
"cabeee-20reuse-nescoSCOPT.py nescoSCOPT 20-reuse.json 20-reuse-in3node.hosting topo-cabeee-3node.json"



# 20 Scramble (using 3node topology)
#"cabeee-20scrambled-orchestratorA.py orchA 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
#"cabeee-20scrambled-orchestratorB.py orchB 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
#"cabeee-20scrambled-nesco.py nesco 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
#"cabeee-20scrambled-nescoSCOPT.py nescoSCOPT 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
# 20 Parallel (using 3node topology)
#"cabeee-20parallel-orchestratorA.py orchA 20-parallel.json 20-parallel-in3node.hosting topo-cabeee-3node.json"
#"cabeee-20parallel-orchestratorB.py orchB 20-parallel.json 20-parallel-in3node.hosting topo-cabeee-3node.json"
#"cabeee-20parallel-nesco.py nesco 20-parallel.json 20-parallel-in3node.hosting topo-cabeee-3node.json"
#"cabeee-20parallel-nescoSCOPT.py nescoSCOPT 20-parallel.json 20-parallel-in3node.hosting topo-cabeee-3node.json"
)


example_log="$MININDN_HOME/example.log"
consumer_log="/tmp/minindn/user/cabeee_consumer.log"
csv_out="$MININDN_HOME/perf-results-emulation.csv"
header="Example, Interest Packets Generated, Data Packets Generated, Interest Packets Transmitted, Data Packets Transmitted, Service Latency(s), Avg Interest Processing(s), CPM, CPM-t_exec(ns), Final Result, Time, mini-ndn commit, ndn-cxx commit, NFD commit, NLSR commit"

if [ ! -f "$csv_out" ]; then
	echo "Creating csv..."
	echo "$header" > "$csv_out"
elif ! grep -q -F "$header" "$csv_out"; then
	echo "Overwriting csv..."
	mv "$csv_out" "$csv_out.bak"
	echo "$header" > "$csv_out"
else
	#echo "Updating csv..."
	#cp "$csv_out" "$csv_out.bak"
	echo "Overwriting csv..."
	mv "$csv_out" "$csv_out.bak"
	echo "$header" > "$csv_out"
fi

#for script in "${scripts[@]}"
for iterator in "${scenarios[@]}"
do
	#echo "Example: $script"

	read -a itrArray <<< "$iterator" #default whitespace IFS
	script=${itrArray[0]}
	type=${itrArray[1]}
	wf=${WORKFLOW_DIR}/${itrArray[2]}
	hosting=${WORKFLOW_DIR}/${itrArray[3]}
	topo=${TOPOLOGY_DIR}/${itrArray[4]}
	echo -en "Scenario: $script\r\n"
	echo -en "type: $type\r\n"
	echo -en "Workflow for CPM calculation: $wf\r\n"
	echo -en "Hosting for CPM calculation: $hosting\r\n"
	echo -en "Topology for CPM calculation: $topo\r\n"

	for sample in $(seq 1 $numSamples);
	do
		now="$(date -Iseconds)"

		minindn_hash="$(git -C "$MININDN_HOME" rev-parse HEAD)"
		ndncxx_hash="$(git -C "$MININDN_HOME/dl/ndn-cxx" rev-parse HEAD)"
		nfd_hash="$(git -C "$MININDN_HOME/dl/NFD" rev-parse HEAD)"
		nlsr_hash="$(git -C "$MININDN_HOME/dl/NLSR" rev-parse HEAD)"

		# these sed scripts depend on the order in which the logs are printed

		echo "   Running sample #${sample}..."
		sudo rm -rf /tmp/minindn/*
		packets=$( \
			sudo -E python "$script_dir/$script" |& tee "$example_log" | sed -n \
			-e 's/^Interest Packets Generated: \([0-9]*\) interests$/\1,/p' \
			-e 's/^Data Packets Generated: \([0-9]*\) data$/\1,/p' \
			-e 's/^Interest Packets Transmitted: \([0-9]*\) interests$/\1,/p' \
			-e 's/^Data Packets Transmitted: \([0-9]*\) data/\1,/p' \
			-e 's/^Average interest processing time (total): \([0-9]*\.[0-9]*\) seconds/\1,/p' \
			| tr -d '\n' \
		)

		echo "   Parsing logs..."
		interest_gen="$(echo "$packets" | cut -d',' -f1)"
		data_gen="$(echo "$packets" | cut -d',' -f2)"
		interest_trans="$(echo "$packets" | cut -d',' -f3)"
		data_trans="$(echo "$packets" | cut -d',' -f4)"
		# python scripts go through log files (all devices) and get the average for NDF and average for ndn-cxx to process interests. They add up both averages, and report them
		interest_processing="$(echo "$packets" | cut -d',' -f5)"

		consumer_parse=$( \
			sed -n \
			-e 's/^\s*The final answer is: \([0-9]*\)$/\1,/p' \
			-e 's/^\s*Service Latency: \([0-9\.]*\) seconds.$/\1,/p' \
			"$consumer_log" \
			| tr -d '\n' \
		)

		result="$(echo "$consumer_parse" | cut -d',' -f1)"
		latency="$(echo "$consumer_parse" | cut -d',' -f2)"

#		cpm=$( \
#			python3 ${NDNCXX_DIR}/critical-path-metric.py -type ${type} -workflow ${wf} -hosting ${hosting} -topology ${topo} | sed -n \
#			-e 's/^metric is \([0-9]*\)/\1/p' \
#			| tr -d '\n' \
#		)
#		cpm_t=$( \
#			python3 ${NDNCXX_DIR}/critical-path-metric.py -type ${type} -workflow ${wf} -hosting ${hosting} -topology ${topo} | sed -n \
#			-e 's/^time is \([0-9]*\)/\1/p' \
#			| tr -d '\n' \
#		)
		cpm=$( \
			${CPM_DIR}/cpm --scheme ${type} --workflow ${wf} --hosting ${hosting} --topology ${topo} | sed -n \
			-e 's/^metric: \([0-9]*\)/\1/p' \
			| tr -d '\n' \
		)
		cpm_t=$( \
			${CPM_DIR}/cpm --scheme ${type} --workflow ${wf} --hosting ${hosting} --topology ${topo} | sed -n \
			-e 's/^time: \([0-9]*\) ns/\1/p' \
			| tr -d '\n' \
		)

		row="$script, $interest_gen, $data_gen, $interest_trans, $data_trans, $latency, $interest_processing, $cpm, $cpm_t, $result, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"

		echo "   Dumping to csv..."
		# replace existing line
		#line_num="$(grep -n -F "$script," "$csv_out" | cut -d: -f1 | head -1)"
		#if [ -n "$line_num" ]; then
			#sed --in-place -e "${line_num}c\\$row" "$csv_out"
		#else
			#echo "$row" >> "$csv_out"
		#fi
		# don't replace, just add this run to the bottom of the file
		echo "$row" >> "$csv_out"

		echo ""
	done
done

echo "All examples ran"
