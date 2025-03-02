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
	# 20 Reuse (Abilene topology)
	"cabeee-intervals-20reuse-orchestratorA.py orchA 20-reuse.json 20-reuse-inAbilene.hosting topo-cabeee-Abilene.json"
####"cabeee-intervals-20reuse-orchestratorB.py orchB 20-reuse.json 20-reuse-inAbilene.hosting topo-cabeee-Abilene.json"
	"cabeee-intervals-20reuse-nesco.py nesco 20-reuse.json 20-reuse-inAbilene.hosting topo-cabeee-Abilene.json"
	"cabeee-intervals-20reuse-nescoSCOPT.py nescoSCOPT 20-reuse.json 20-reuse-inAbilene.hosting topo-cabeee-Abilene.json"



	# 20 Sensor (using 3node topology)
	#"cabeee-intervals-20sensor-orchestratorA.py orchA 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
####"cabeee-intervals-20sensor-orchestratorB.py orchB 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20sensor-nesco.py nesco 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20sensor-nescoSCOPT.py nescoSCOPT 20-sensor.json 20-sensor-in3node.hosting topo-cabeee-3node.json"
	# 20 Linear (using 3node topology)
	#"cabeee-intervals-20linear-orchestratorA.py orchA 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
####"cabeee-intervals-20linear-orchestratorB.py orchB 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20linear-nesco.py nesco 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20linear-nescoSCOPT.py nescoSCOPT 20-linear.json 20-linear-in3node.hosting topo-cabeee-3node.json"
	# 20 Scramble (using 3node topology)
	#"cabeee-intervals-20scrambled-orchestratorA.py orchA 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
####"cabeee-intervals-20scrambled-orchestratorB.py orchB 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20scrambled-nesco.py nesco 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
	#"cabeee-intervals-20scrambled-nescoSCOPT.py nescoSCOPT 20-linear.json 20-scramble-in3node.hosting topo-cabeee-3node.json"
)


example_log="$MININDN_HOME/example.log"
sensor_scenario_log="/tmp/minindn/rtr-e1a/cabeee_consumer_20sensor.log"
linear_scenario_log="/tmp/minindn/rtr-h1a/cabeee_consumer_20linear.log"
reuse_scenario_log="/tmp/minindn/rtr-f2a/cabeee_consumer_20reuse.log"
csv_out="$MININDN_HOME/perf-results-emulation_intervals_reuse.csv"
header="Scenario/Scheme, Scenario, Min Service Latency(s), Low Quartile Service Latency(s), Mid Quartile Service Latency(s), High Quartile Service Latency(s), Max Service Latency(s), Total Service Latency(s), Avg Service Latency(s), Requests Fulfilled, Final Result, Time, mini-ndn commit, ndn-cxx commit, NFD commit, NLSR commit"

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
		sudo -E python "$script_dir/$script" |& tee "$example_log"

		echo "   Parsing logs..."
		latencies=$( \
			python process_nfd_logs_intervals_reuse.py "$reuse_scenario_log" | sed -n \
			-e 's/^\s*consumerR min latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR low latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR mid latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR high latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR max latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR total latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR avg latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerR requests fulfilled: \([0-9\.]*\) total requests$/\1,/p' \
			-e 's/^\s*consumerR Final answer: \([0-9\.]*\) numerical$/\1,/p' \
			| tr -d '\n' \
		)
		reuse_min_latency="$(echo "$latencies" | cut -d',' -f1)"
		reuse_low_latency="$(echo "$latencies" | cut -d',' -f2)"
		reuse_mid_latency="$(echo "$latencies" | cut -d',' -f3)"
		reuse_high_latency="$(echo "$latencies" | cut -d',' -f4)"
		reuse_max_latency="$(echo "$latencies" | cut -d',' -f5)"
		reuse_total_latency="$(echo "$latencies" | cut -d',' -f6)"
		reuse_avg_latency="$(echo "$latencies" | cut -d',' -f7)"
		reuse_requests_fulfilled="$(echo "$latencies" | cut -d',' -f8)"
		reuse_final_answer="$(echo "$latencies" | cut -d',' -f9)"


		latencies=$( \
			python process_nfd_logs_intervals_reuse.py "$linear_scenario_log" | sed -n \
			-e 's/^\s*consumerL min latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL low latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL mid latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL high latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL max latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL total latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL avg latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerL requests fulfilled: \([0-9\.]*\) total requests$/\1,/p' \
			-e 's/^\s*consumerL Final answer: \([0-9\.]*\) numerical$/\1,/p' \
			| tr -d '\n' \
		)
		linear_min_latency="$(echo "$latencies" | cut -d',' -f1)"
		linear_low_latency="$(echo "$latencies" | cut -d',' -f2)"
		linear_mid_latency="$(echo "$latencies" | cut -d',' -f3)"
		linear_high_latency="$(echo "$latencies" | cut -d',' -f4)"
		linear_max_latency="$(echo "$latencies" | cut -d',' -f5)"
		linear_total_latency="$(echo "$latencies" | cut -d',' -f6)"
		linear_avg_latency="$(echo "$latencies" | cut -d',' -f7)"
		linear_requests_fulfilled="$(echo "$latencies" | cut -d',' -f8)"
		linear_final_answer="$(echo "$latencies" | cut -d',' -f9)"


		latencies=$( \
			python process_nfd_logs_intervals_reuse.py "$sensor_scenario_log" | sed -n \
			-e 's/^\s*consumerS min latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS low latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS mid latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS high latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS max latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS total latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS avg latency: \([0-9\.]*\) seconds$/\1,/p' \
			-e 's/^\s*consumerS requests fulfilled: \([0-9\.]*\) total requests$/\1,/p' \
			-e 's/^\s*consumerS Final answer: \([0-9\.]*\) numerical$/\1,/p' \
			| tr -d '\n' \
		)
		sensor_min_latency="$(echo "$latencies" | cut -d',' -f1)"
		sensor_low_latency="$(echo "$latencies" | cut -d',' -f2)"
		sensor_mid_latency="$(echo "$latencies" | cut -d',' -f3)"
		sensor_high_latency="$(echo "$latencies" | cut -d',' -f4)"
		sensor_max_latency="$(echo "$latencies" | cut -d',' -f5)"
		sensor_total_latency="$(echo "$latencies" | cut -d',' -f6)"
		sensor_avg_latency="$(echo "$latencies" | cut -d',' -f7)"
		sensor_requests_fulfilled="$(echo "$latencies" | cut -d',' -f8)"
		sensor_final_answer="$(echo "$latencies" | cut -d',' -f9)"


		row1="$script, 20-sensor, $sensor_min_latency, $sensor_low_latency, $sensor_mid_latency, $sensor_high_latency, $sensor_max_latency, $sensor_total_latency, $sensor_avg_latency, $sensor_requests_fulfilled, $sensor_final_answer, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"
		row2="$script, 20-linear, $linear_min_latency, $linear_low_latency, $linear_mid_latency, $linear_high_latency, $linear_max_latency, $linear_total_latency, $linear_avg_latency, $linear_requests_fulfilled, $linear_final_answer, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"
		row3="$script, 20-reuse, $reuse_min_latency, $reuse_low_latency, $reuse_mid_latency, $reuse_high_latency, $reuse_max_latency, $reuse_total_latency, $reuse_avg_latency, $reuse_requests_fulfilled, $reuse_final_answer, $now, $minindn_hash, $ndncxx_hash, $nfd_hash, $nlsr_hash"


		echo "   Dumping to csv..."
		# replace existing line
		#line_num="$(grep -n -F "$script," "$csv_out" | cut -d: -f1 | head -1)"
		#if [ -n "$line_num" ]; then
			#sed --in-place -e "${line_num}c\\$row" "$csv_out"
		#else
			echo "$row1" >> "$csv_out"
			echo "$row2" >> "$csv_out"
			echo "$row3" >> "$csv_out"
		#fi
		# don't replace, just add this run to the bottom of the file
		#echo "$row" >> "$csv_out"

		echo ""
	done
done

echo "All examples ran"
