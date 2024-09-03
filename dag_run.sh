#!/bin/bash


#----- THIS ONLY NEEDS TO BE RUN ONCE --------------------
#cd ~/mini-ndn/dl/ndn-cxx
#./waf clean
#./waf
#sudo ./waf install
#---------------------------------------------------------

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

for script in "${scripts[@]}"
do
        sudo -E python "$script_dir/$script"
	# show the consumer log (so we can see the final answer and the service latency)
        cat /tmp/minindn/user/cabeee_consumer.log
	#cat /tmp/minindn/user/cabeee_consumer2.log
done
