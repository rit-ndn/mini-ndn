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
NDNCXX_DIR="$HOME/mini-ndn/dl/ndn-cxx/run_scripts_hardware"
WORKFLOW_DIR="$NDNCXX_DIR/workflows"
TOPOLOGY_DIR="$NDNCXX_DIR/topologies"
CPM_DIR="$MININDN_HOME/dl/CPM"


script_dir="$MININDN_HOME/examples"


declare -a scenarios=(
	# 20 Sensor (using 3node topology)
	"cabeee-intervals-20sensor-orchestratorA.py orchA 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
####"cabeee-intervals-20sensor-orchestratorB.py orchB 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20sensor-nesco.py nesco 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20sensor-nescoSCOPT.py nescoSCOPT 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	# 20 Linear (using 3node topology)
	"cabeee-intervals-20linear-orchestratorA.py orchA 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
####"cabeee-intervals-20linear-orchestratorB.py orchB 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20linear-nesco.py nesco 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20linear-nescoSCOPT.py nescoSCOPT 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	# 20 Scramble (using 3node topology)
	"cabeee-intervals-20scrambled-orchestratorA.py orchA 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
####"cabeee-intervals-20scrambled-orchestratorB.py orchB 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20scrambled-nesco.py nesco 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	"cabeee-intervals-20scrambled-nescoSCOPT.py nescoSCOPT 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
)


example_log="$MININDN_HOME/example.log"
consumer_log="/tmp/minindn/user/cabeee_consumer.log"
csv_out="$MININDN_HOME/perf-results-emulation_intervals.csv"
header="Example, Min Service Latency(s), Low Quartile Service Latency(s), Mid Quartile Service Latency(s), High Quartile Service Latency(s), Max Service Latency(s), Total Service Latency(s), Avg Service Latency(s), Requests Fulfilled, Final Result, Time, mini-ndn commit, ndn-cxx commit, NFD commit, NLSR commit"

if [ ! -f "$csv_out" ]; then
	echo "Creating csv..."
	echo "$header" > "$csv_out"
elif ! grep -q -F "$header" "$csv_out"; then
	echo "Overwriting csv..."
	mv "$csv_out" "$csv_out.bak"
	echo "$header" > "$csv_out"
else
	echo "Updating csv..."
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
		sudo -E python "$script_dir/$script" |& tee "$example_log"

		echo "   Parsing logs..."
		latencies=$( \
			python process_nfd_logs_intervals.py "$consumer_log" | sed -n \
			-e 's/^\s*consumer min latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer low latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer mid latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer high latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer max latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer total latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer avg latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumer requests fulfilled: \([0-9\.]*\) total requests$/\1,/p' \
			-e 's/^\s*consumer Final answer: \([0-9\.]*\) numerical$/\1,/p' \
			| tr -d '\n' \
		)
		min_latency="$(echo "$latencies" | cut -d',' -f1)"
		low_latency="$(echo "$latencies" | cut -d',' -f2)"
		mid_latency="$(echo "$latencies" | cut -d',' -f3)"
		high_latency="$(echo "$latencies" | cut -d',' -f4)"
		max_latency="$(echo "$latencies" | cut -d',' -f5)"
		total_latency="$(echo "$latencies" | cut -d',' -f6)"
		avg_latency="$(echo "$latencies" | cut -d',' -f7)"
		requests_fulfilled="$(echo "$latencies" | cut -d',' -f8)"
		final_answer="$(echo "$latencies" | cut -d',' -f9)"



		row="$script, $min_latency, $low_latency, $mid_latency, $high_latency, $max_latency, $total_latency, $avg_latency, $requests_fulfilled, $final_answer, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"

		echo "   Dumping to csv..."
		# replace existing line
		line_num="$(grep -n -F "$script," "$csv_out" | cut -d: -f1 | head -1)"
		if [ -n "$line_num" ]; then
			sed --in-place -e "${line_num}c\\$row" "$csv_out"
		else
			echo "$row" >> "$csv_out"
		fi
		# don't replace, just add this run to the bottom of the file
		#echo "$row" >> "$csv_out"

		echo ""
	done
done

echo "All examples ran"
