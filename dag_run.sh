#! /bin/bash


#----- THIS ONLY NEEDS TO BE RUN ONCE --------------------
#cd ~/mini-ndn/dl/ndn-cxx
#./waf clean
#./waf
#sudo ./waf install
#---------------------------------------------------------


clear

# 4 DAG
#sudo python examples/cabeee-4dag-orchestratorA.py
#sudo python examples/cabeee-4dag-orchestratorB.py
sudo python examples/cabeee-4dag.py

# 20 Linear
#sudo python examples/cabeee-20node-linear-orchestratorA.py
#sudo python examples/cabeee-20node-linear-orchestratorB.py
#sudo python examples/cabeee-20node-linear.py


# 20 Parallel
#sudo python examples/cabeee-20node-parallel-orchestratorA.py
#sudo python examples/cabeee-20node-parallel-orchestratorB.py
#sudo python examples/cabeee-20node-parallel.py


# 20 Sensor (Parallel)
#sudo python examples/cabeee-20sensro-parallel-orchestratorA.py
#sudo python examples/cabeee-20sensro-parallel-orchestratorB.py
#sudo python examples/cabeee-20sensro-parallel.py


# 8 DAG
#sudo python examples/cabeee-8dag-orchestratorA.py
#sudo python examples/cabeee-8dag-orchestratorB.py
#sudo python examples/cabeee-8dag.py


# 8 DAG w/ caching
#sudo python examples/cabeee-8dag-caching-orchestratorA.py
#sudo python examples/cabeee-8dag-caching-orchestratorB.py
#sudo python examples/cabeee-8dag-caching.py







