#!/bin/bash

#----- THIS ONLY NEEDS TO BE RUN ONCE --------------------
#cd ~/mini-ndn/dl/ndn-cxx
#./waf clean
#./waf
#sudo ./waf install
#---------------------------------------------------------

set -e


numSamples=1

MININDN_HOME="$HOME/mini-ndn"
NDNCXX_DIR="$HOME/mini-ndn/dl/ndn-cxx/run_scripts"
WORKFLOW_DIR="$NDNCXX_DIR/workflows"
TOPOLOGY_DIR="$NDNCXX_DIR/topologies"


script_dir="$MININDN_HOME/examples"


declare -a scenarios=(
	# 20 Sensor (using 3node topology)
	#"cabeee-intervals-20sensor-orchestratorA.py orchA 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20sensor-orchestratorB.py orchB 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20sensor-nesco.py nesco 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20sensor-nescoSCOPT.py nescoSCOPT 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	# 20 Linear (using 3node topology)
	#"cabeee-intervals-20linear-orchestratorA.py orchA 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20linear-orchestratorB.py orchB 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20linear-nesco.py nesco 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20linear-nescoSCOPT.py nescoSCOPT 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	# 20 Scramble (using 3node topology)
	#"cabeee-intervals-20scrambled-orchestratorA.py orchA 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20scrambled-orchestratorB.py orchB 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20scrambled-nesco.py nesco 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20scrambled-nescoSCOPT.py nescoSCOPT 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
)


example_log="$MININDN_HOME/example.log"
consumer_log="/tmp/minindn/user/cabeee_consumer.log"
csv_out="$MININDN_HOME/perf-results-emulation_intervals.csv"
header="Example, Interest Packets Generated, Data Packets Generated, Interest Packets Transmitted, Data Packets Transmitted, Service Latency(s), Avg Interest Processing(s), CPM, CPM-t_exec(ns), Min Service Latency (us), Low Quartile Service Latency (us), Avg Service Latency (us), High Quartile Service Latency (us), Max Service Latency (us), Total Service Latency(us), Final Result, Time, mini-ndn commit, ndn-cxx commit, NFD commit, NLSR commit"

if [ ! -f "$csv_out" ]; then
	echo "$header" > "$csv_out"
elif ! grep -q -F "$header" "$csv_out"; then
	mv "$csv_out" "$csv_out.bak"
	echo "Overwriting csv..."
	echo "$header" > "$csv_out"
else
	cp "$csv_out" "$csv_out.bak"
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
			"$consumer_log" \
			| tr -d '\n' \
		)
		result="$(echo "$consumer_parse" | cut -d',' -f1)"



		latencies=$( \
			python process_nfd_logs_intervals.py | sed -n \
			-e 's/^\s*min latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*low latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*avg latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*high latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*max latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*total latency: \([0-9\.]*\) seconds$/\1,/p' \
			| tr -d '\n' \
		)
		min_latency="$(echo "$latencies" | cut -d',' -f1)"
		low_latency="$(echo "$latencies" | cut -d',' -f2)"
		avg_latency="$(echo "$latencies" | cut -d',' -f3)"
		high_latency="$(echo "$latencies" | cut -d',' -f4)"
		max_latency="$(echo "$latencies" | cut -d',' -f5)"
		total_latency="$(echo "$latencies" | cut -d',' -f6)"

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
			dl/CPM/cpm --scheme ${type} --workflow ${wf} --hosting ${hosting} --topology ${topo} | sed -n \
			-e 's/^metric: \([0-9]*\)/\1/p' \
			| tr -d '\n' \
		)
		cpm_t=$( \
			dl/CPM/cpm --scheme ${type} --workflow ${wf} --hosting ${hosting} --topology ${topo} | sed -n \
			-e 's/^time: \([0-9]*\) ns/\1/p' \
			| tr -d '\n' \
		)

		row="$script, $interest_gen, $data_gen, $interest_trans, $data_trans, $latency, $interest_processing, $cpm, $cpm_t, $min_latency, $low_latency, $avg_latency, $high_latency, $max_latency, $total_latency, $result, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"

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
