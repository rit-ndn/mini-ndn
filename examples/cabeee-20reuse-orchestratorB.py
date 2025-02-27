# -*- Mode:python; c-file-style:"gnu"; indent-tabs-mode:nil -*- */
#
# Copyright (C) 2015-2021, The University of Memphis,
#                          Arizona Board of Regents,
#                          Regents of the University of California.
#
# This file is part of Mini-NDN.
# See AUTHORS.md for a complete list of Mini-NDN authors and contributors.
#
# Mini-NDN is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mini-NDN is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mini-NDN, e.g., in COPYING.md file.
# If not, see <http://www.gnu.org/licenses/>.

#from subprocess import PIPE
import subprocess

from mininet.log import setLogLevel, info
from mininet.topo import Topo

from minindn.minindn import Minindn
from minindn.apps.app_manager import AppManager
from minindn.util import MiniNDNCLI, getPopen
from minindn.apps.nfd import Nfd
from minindn.helpers.nfdc import Nfdc
from minindn.helpers.ndn_routing_helper import NdnRoutingHelper
import argparse
from minindn.apps.nlsr import Nlsr
from minindn.helpers.ip_routing_helper import IPRoutingHelper
from minindn.helpers.merge_nfd_logs import MergeNFDLogs
from minindn.util import copyExistentFile

from time import sleep
from os import environ

import sys

PREFIX = "/orchB"

USER_HOME = environ['HOME']
MININDN_DIR = USER_HOME + '/mini-ndn'
WORKFLOW = MININDN_DIR + '/workflows/20-reuse.json'
TOPOLOGY = MININDN_DIR + '/topologies/cabeee-3node.conf'

BIN_DIR = MININDN_DIR + '/dl/ndn-cxx/build/examples'

def run():
    Minindn.cleanUp()
    Minindn.verifyDependencies()

    MergeNFDLogs.deleteAllLogs()




    """
    There are multiple ways of setting up routes in Mini-NDN
    refer: https://minindn.memphis.edu/experiment.html#routing-options
    """
    routeOption = 2


    if routeOption == 0:
        # OPTION 0
        # set up routes manually. The important bit to note here is the use of the Nfdc command

        ndn = Minindn(topoFile=TOPOLOGY)
        ndn.start()
        info('Setting up routes manually in NFD\n')
        links = {   "sensor":["rtr1"],
                    "rtr1":["rtr2"],
                    "rtr2":["rtr3"],
                    "rtr3":["user"]}
        for first in links:
            for second in links[first]:
                host1 = ndn.net[first]
                host2 = ndn.net[second]
                interface = host2.connectionsTo(host1)[0][0]
                interface_ip = interface.IP()
                Nfdc.createFace(host1, interface_ip)
                Nfdc.registerRoute(host1, PREFIX, interface_ip, cost=0)

        sleep(1)

    if routeOption == 1:
        # OPTION 1
        # set up routes using Link State Routing (NLSR).

        ndn = Minindn(topoFile=TOPOLOGY)
        ndn.start()

        info('Adding IP routes to NFD\n')
        #info('Starting NFD on nodes\n')
        nfds = AppManager(ndn, ndn.net.hosts, Nfd, logLevel="DEBUG")
        info('Starting NLSR on nodes\n')
        nlsrs = AppManager(ndn, ndn.net.hosts, Nlsr)

        sleep(90)

    if routeOption == 2:
        # OPTION 2
        # use static routing as used in static_routing_experiment.py
    
        # the following parser came from static_routing_experiment.py
        parser = argparse.ArgumentParser()
        parser.add_argument('--face-type', dest='faceType', default='udp', choices=['udp', 'tcp'])
        parser.add_argument('--routing', dest='routingType', default='link-state',
                            choices=['link-state', 'hr', 'dry'],
                            help='''Choose routing type, dry = link-state is used
                                    but hr is calculated for comparision.''')

        ndn = Minindn(parser=parser, topoFile=TOPOLOGY)
        ndn.start()

        # configure and start nfd on each node
        info("Configuring NFD\n")
        #nfds = AppManager(ndn, ndn.net.hosts, Nfd, logLevel="DEBUG")
        nfds = AppManager(ndn, [ndn.net['sensor']], Nfd, logLevel="INFO", csSize=0)
        nfds = AppManager(ndn, [ndn.net['rtr1']], Nfd, logLevel="INFO", csSize=1000)
        nfds = AppManager(ndn, [ndn.net['rtr2']], Nfd, logLevel="INFO", csSize=1000)
        nfds = AppManager(ndn, [ndn.net['rtr3']], Nfd, logLevel="INFO", csSize=1000)
        nfds = AppManager(ndn, [ndn.net['user']], Nfd, logLevel="INFO", csSize=0)

        info('Adding static routes to NFD\n')
        grh = NdnRoutingHelper(ndn.net, ndn.args.faceType, ndn.args.routingType)
        # For all host, pass ndn.net.hosts or a list, [ndn.net['a'], ..] or [ndn.net.hosts[0],.]
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensor1"])
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensor2"])
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensor3"])
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensor4"])
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensor5"])
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensor6"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP1"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP2"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP3"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP4"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP5"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP6"])
        grh.addOrigin([ndn.net['sensor']], [PREFIX + "/sensorL"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceL1"])
        grh.addOrigin([ndn.net['rtr1']], [PREFIX + "/serviceL2"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceL3"])
        grh.addOrigin([ndn.net['rtr3']], [PREFIX + "/serviceL4"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceL5"])
        grh.addOrigin([ndn.net['rtr1']], [PREFIX + "/serviceL6"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceL7"])
        grh.addOrigin([ndn.net['rtr3']], [PREFIX + "/serviceL8"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceL9"])
        grh.addOrigin([ndn.net['rtr1']], [PREFIX + "/serviceL10"])
        grh.addOrigin([ndn.net['rtr3']], [PREFIX + "/serviceP22"])
        grh.addOrigin([ndn.net['rtr3']], [PREFIX + "/serviceP23"])
        grh.addOrigin([ndn.net['rtr3']], [PREFIX + "/serviceR1"])
        grh.addOrigin([ndn.net['user']], [PREFIX + "/serviceOrchestration"])
        grh.calculateNPossibleRoutes() 

        ''' 
        #PREFIX is advertised from node "sensor", it should be reachable from all other nodes.
        routesFromSensor = ndn.net['sensor'].cmd("nfdc route | grep -v '/localhost/nfd'")
        if '/ndn/rtr1-site/rtr1' not in routesFromSensor or \
           '/ndn/rtr2-site/rtr2' not in routesFromSensor or \
           '/ndn/rtr3-site/rtr3' not in routesFromSensor or \
           '/ndn/orch-site/orch' not in routesFromSensor or \
           '/ndn/user-site/user' not in routesFromSensor:
            info("Route addition failed\n")
        routesToPrefix = ndn.net['rtr1'].cmd("nfdc fib | grep '/orchB'")
        if '/orchB' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['rtr2'].cmd("nfdc fib | grep '/orchB'")
        if '/orchB' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['rtr3'].cmd("nfdc fib | grep '/orchB'")
        if '/orchB' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['orch'].cmd("nfdc fib | grep '/orchB'")
        if '/orchB' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        ''' 
        info('Route addition to NFD completed\n')

        sleep(1)

    if routeOption == 3:
        # OPTION 3
        # use IP routing as used in ip_rounting_experiment.py

        ndn = Minindn(topoFile=TOPOLOGY)
        ndn.start()

        # NOTE: this method is also used in traffic_generator.py, pcap_logging_experiment.py, and consumer-producer.py
        info('Adding IP routes to NFD\n')
        #info('Starting NFD on nodes\n')
        nfds = AppManager(ndn, ndn.net.hosts, Nfd, logLevel="DEBUG")
        info('Starting NLSR on nodes\n')
        nlsrs = AppManager(ndn, ndn.net.hosts, Nlsr)

        # Calculate all routes for IP routing
        IPRoutingHelper.calcAllRoutes(ndn.net)
        info("IP routes configured\n")

        sleep(90)







    # SET UP THE PRODUCER
    info('Starting Producer App\n')
    # runs in the background so that it is non-blocking
    # App input is the service PREFIX
    producer = ndn.net['sensor']
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor1", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor2", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor3", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor4", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor5", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor6", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-custom-app-producer {} {} {} {} {} {} > cabeee_producer.log &'.format(PREFIX, "/sensorL", 9000, 0, 100, 1000)
    producer.cmd(cmd)
    

    sleep(1)


    # SET UP THE SERVICES
    # run the cabeee-dag-serviceB-app application on all router nodes
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceP1")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceP2")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceP3")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceP4")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceP5")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceP6")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)

    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service1.log &'.format(PREFIX, "/serviceL1")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service2.log &'.format(PREFIX, "/serviceL2")
    ndn.net['rtr1'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service3.log &'.format(PREFIX, "/serviceL3")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service4.log &'.format(PREFIX, "/serviceL4")
    ndn.net['rtr3'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service5.log &'.format(PREFIX, "/serviceL5")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service6.log &'.format(PREFIX, "/serviceL6")
    ndn.net['rtr1'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service7.log &'.format(PREFIX, "/serviceL7")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service8.log &'.format(PREFIX, "/serviceL8")
    ndn.net['rtr3'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service9.log &'.format(PREFIX, "/serviceL9")
    ndn.net['rtr2'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service10.log &'.format(PREFIX, "/serviceL10")
    ndn.net['rtr1'].cmd(cmd)
    sleep(0.1)

    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service10.log &'.format(PREFIX, "/serviceP22")
    ndn.net['rtr3'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service10.log &'.format(PREFIX, "/serviceP23")
    ndn.net['rtr3'].cmd(cmd)
    sleep(0.1)
    cmd = BIN_DIR + '/cabeee-dag-serviceB-app {} {} > cabeee_serviceB_service10.log &'.format(PREFIX, "/serviceR1")
    ndn.net['rtr3'].cmd(cmd)
    sleep(0.1)




    # SET UP THE ORCHESTRATOR
    # run the cabeee-dag-orchestratorB-app application on all router nodes
    cmd = BIN_DIR + '/cabeee-dag-orchestratorB-app {} {} > cabeee_orchestratorB.log &'.format(PREFIX, "/serviceOrchestration")
    #ndn.net['orch'].cmd(cmd)
    ndn.net['user'].cmd(cmd)

    # SET UP THE CONSUMER
    info('Starting Consumer App (after waiting one second for RIB updates to finish propagating)\n')
    sleep(3) # wait so that we don't start the consumer until all RIB updates have propagated
    # App input is the main PREFIX, the workflow file, and the orchestration value (0, 1 or 2)
    cmd = BIN_DIR + '/cabeee-custom-app-consumer {} {} {} > cabeee_consumer.log &'.format(PREFIX, WORKFLOW, 2)
    consumer = ndn.net['user']
    consumer.cmd(cmd)


    sleep(3)







    info("\nExperiment Completed!\n")
    #MiniNDNCLI(ndn.net)
    ndn.stop()

    # concatenate every node's log/nfd.log file to a single one. Keep timestamp, add node name. Sort by timestamp!
    MergeNFDLogs.mergeAllLogs()

if __name__ == '__main__':
    setLogLevel("info")
    #setLogLevel("debug")
    run()
