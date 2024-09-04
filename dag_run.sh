#!/bin/bash

#----- THIS ONLY NEEDS TO BE RUN ONCE --------------------
#cd ~/mini-ndn/dl/ndn-cxx
#./waf clean
#./waf
#sudo ./waf install
#---------------------------------------------------------

set -eou pipefail

MININDN_HOME="$HOME/mini-ndn"

script_dir="$MININDN_HOME/examples"
scripts=(
# 4 DAG
#       "cabeee-4dag-archestratorA.py"
#       "cabeee-4dag-archestratorB.py"
        "cabeee-4dag.py"
# 20 Linear
#       "cabeee-20node-linear-orchestratorA.py"
#       "cabeee-20node-linear-orchestratorB.py"
#       "cabeee-20node-linear.py"
# 20 Parallel
#       "cabeee-20node-parallel-orchestratorA.py"
#       "cabeee-20node-parallel-orchestratorB.py"
#       "cabeee-20node-parallel.py"
# 20 Sensor (Parallel)
#       "cabeee-20sensor-parallel-orchestratorA.py"
#       "cabeee-20sensor-parallel-orchestratorB.py"
#       "cabeee-20sensor-parallel.py"
# 8 DAG
#       "cabeee-8dag-orchestratorA.py"
#       "cabeee-8dag-orchestratorB.py"
#       "cabeee-8dag.py"
# 8 DAG w/ caching
#       "cabeee-8dag-caching-orchestratorA.py"
#       "cabeee-8dag-caching-orchestratorB.py"
#       "cabeee-8dag-caching.py"
# other examples
#       "cabeee-chunks.py"
        )

#clear

example_log="$MININDN_HOME/example.log"
consumer_log="/tmp/minindn/user/cabeee_consumer.log"
csv_out="$MININDN_HOME/$(date +'%Y%m%d%H%M%S')-perf.csv"
header="Example, Interest Packets Generated, Data Packets Generated, Interest Packets Transmitted, Data Packets Transmitted, Final Result, Service Latency"

echo "$header" > "$csv_out"

for script in "${scripts[@]}"
do
	# shellcheck disable=SC2024
        sudo -E python "$script_dir/$script" > "$example_log"
	packets=$(sed -n \
		-e 's/^Interest Packets Generated: \([0-9]*\) interests$/\1, /p' \
		-e 's/^Data Packets Generated: \([0-9]*\) data$/\1, /p' \
		-e 's/^Interest Packets Transmitted: \([0-9]*\) interests$/\1, /p' \
		-e 's/^Data Packets Transmitted: \([0-9]*\) data/\1/p' \
		"$example_log" \
		| tr -d '\n' \
	)
	consumer_cols=$(sed -n \
		-e 's/^\s*The final answer is: \([0-9]*\)$/\1, /p' \
		-e 's/^\s*Service Latency: \([0-9\.]*\) seconds.$/\1/p' \
		"$consumer_log" \
		| tr -d '\n' \
	)
	
	echo "$script, $packets, $consumer_cols" >> $csv_out
done
