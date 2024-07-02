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

import sys


PREFIX = "/interCACHE"
WORKFLOW = "/home/cabeee/mini-ndn/workflows/20-sensor.json"
TOPOLOGY = "topologies/cabeee-20sensor-parallel.conf"


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
        links = {   "sensor1":["rtr1"],
                    "sensor2":["rtr2"],
                    "sensor3":["rtr3"],
                    "sensor4":["rtr4"],
                    "sensor5":["rtr5"],
                    "sensor6":["rtr6"],
                    "sensor7":["rtr7"],
                    "sensor8":["rtr8"],
                    "sensor9":["rtr9"],
                    "sensor10":["rtr10"],
                    "sensor11":["rtr11"],
                    "sensor12":["rtr12"],
                    "sensor13":["rtr13"],
                    "sensor14":["rtr14"],
                    "sensor15":["rtr15"],
                    "sensor16":["rtr16"],
                    "sensor17":["rtr17"],
                    "sensor18":["rtr18"],
                    "sensor19":["rtr19"],
                    "sensor20":["rtr20"],
                    "rtr1":["rtr21"],
                    "rtr2":["rtr21"],
                    "rtr3":["rtr21"],
                    "rtr4":["rtr21"],
                    "rtr5":["rtr21"],
                    "rtr6":["rtr21"],
                    "rtr7":["rtr21"],
                    "rtr8":["rtr21"],
                    "rtr9":["rtr21"],
                    "rtr10":["rtr21"],
                    "rtr11":["rtr21"],
                    "rtr12":["rtr21"],
                    "rtr13":["rtr21"],
                    "rtr14":["rtr21"],
                    "rtr15":["rtr21"],
                    "rtr16":["rtr21"],
                    "rtr17":["rtr21"],
                    "rtr18":["rtr21"],
                    "rtr19":["rtr21"],
                    "rtr20":["rtr21"],
                    "rtr21":["orch"],
                    "orch":["user"]}
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
        nfds = AppManager(ndn, ndn.net.hosts, Nfd, logLevel="DEBUG")

        info('Adding static routes to NFD\n')
        grh = NdnRoutingHelper(ndn.net, ndn.args.faceType, ndn.args.routingType)
        # For all host, pass ndn.net.hosts or a list, [ndn.net['a'], ..] or [ndn.net.hosts[0],.]
        grh.addOrigin([ndn.net['sensor1']], [PREFIX + "/sensor1"])
        grh.addOrigin([ndn.net['sensor2']], [PREFIX + "/sensor2"])
        grh.addOrigin([ndn.net['sensor3']], [PREFIX + "/sensor3"])
        grh.addOrigin([ndn.net['sensor4']], [PREFIX + "/sensor4"])
        grh.addOrigin([ndn.net['sensor5']], [PREFIX + "/sensor5"])
        grh.addOrigin([ndn.net['sensor6']], [PREFIX + "/sensor6"])
        grh.addOrigin([ndn.net['sensor7']], [PREFIX + "/sensor7"])
        grh.addOrigin([ndn.net['sensor8']], [PREFIX + "/sensor8"])
        grh.addOrigin([ndn.net['sensor9']], [PREFIX + "/sensor9"])
        grh.addOrigin([ndn.net['sensor10']], [PREFIX + "/sensor10"])
        grh.addOrigin([ndn.net['sensor11']], [PREFIX + "/sensor11"])
        grh.addOrigin([ndn.net['sensor12']], [PREFIX + "/sensor12"])
        grh.addOrigin([ndn.net['sensor13']], [PREFIX + "/sensor13"])
        grh.addOrigin([ndn.net['sensor14']], [PREFIX + "/sensor14"])
        grh.addOrigin([ndn.net['sensor15']], [PREFIX + "/sensor15"])
        grh.addOrigin([ndn.net['sensor16']], [PREFIX + "/sensor16"])
        grh.addOrigin([ndn.net['sensor17']], [PREFIX + "/sensor17"])
        grh.addOrigin([ndn.net['sensor18']], [PREFIX + "/sensor18"])
        grh.addOrigin([ndn.net['sensor19']], [PREFIX + "/sensor19"])
        grh.addOrigin([ndn.net['sensor20']], [PREFIX + "/sensor20"])
        grh.addOrigin([ndn.net['rtr1']], [PREFIX + "/serviceP1"])
        grh.addOrigin([ndn.net['rtr2']], [PREFIX + "/serviceP2"])
        grh.addOrigin([ndn.net['rtr3']], [PREFIX + "/serviceP3"])
        grh.addOrigin([ndn.net['rtr4']], [PREFIX + "/serviceP4"])
        grh.addOrigin([ndn.net['rtr5']], [PREFIX + "/serviceP5"])
        grh.addOrigin([ndn.net['rtr6']], [PREFIX + "/serviceP6"])
        grh.addOrigin([ndn.net['rtr7']], [PREFIX + "/serviceP7"])
        grh.addOrigin([ndn.net['rtr8']], [PREFIX + "/serviceP8"])
        grh.addOrigin([ndn.net['rtr9']], [PREFIX + "/serviceP9"])
        grh.addOrigin([ndn.net['rtr10']], [PREFIX + "/serviceP10"])
        grh.addOrigin([ndn.net['rtr11']], [PREFIX + "/serviceP11"])
        grh.addOrigin([ndn.net['rtr12']], [PREFIX + "/serviceP12"])
        grh.addOrigin([ndn.net['rtr13']], [PREFIX + "/serviceP13"])
        grh.addOrigin([ndn.net['rtr14']], [PREFIX + "/serviceP14"])
        grh.addOrigin([ndn.net['rtr15']], [PREFIX + "/serviceP15"])
        grh.addOrigin([ndn.net['rtr16']], [PREFIX + "/serviceP16"])
        grh.addOrigin([ndn.net['rtr17']], [PREFIX + "/serviceP17"])
        grh.addOrigin([ndn.net['rtr18']], [PREFIX + "/serviceP18"])
        grh.addOrigin([ndn.net['rtr19']], [PREFIX + "/serviceP19"])
        grh.addOrigin([ndn.net['rtr20']], [PREFIX + "/serviceP20"])
        grh.addOrigin([ndn.net['rtr21']], [PREFIX + "/serviceP21"])
        grh.addOrigin([ndn.net['orch']], [PREFIX + "/serviceOrchestration"])
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
        routesToPrefix = ndn.net['rtr1'].cmd("nfdc fib | grep '/interCACHE'")
        if '/interCACHE' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['rtr2'].cmd("nfdc fib | grep '/interCACHE'")
        if '/interCACHE' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['rtr3'].cmd("nfdc fib | grep '/interCACHE'")
        if '/interCACHE' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['orch'].cmd("nfdc fib | grep '/interCACHE'")
        if '/interCACHE' not in routesToPrefix:
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
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor1")
    producer = ndn.net['sensor1']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor2")
    producer = ndn.net['sensor2']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor3")
    producer = ndn.net['sensor3']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor4")
    producer = ndn.net['sensor4']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor5")
    producer = ndn.net['sensor5']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor6")
    producer = ndn.net['sensor6']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor7")
    producer = ndn.net['sensor7']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor8")
    producer = ndn.net['sensor8']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor9")
    producer = ndn.net['sensor9']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor10")
    producer = ndn.net['sensor10']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor11")
    producer = ndn.net['sensor11']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor12")
    producer = ndn.net['sensor12']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor13")
    producer = ndn.net['sensor13']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor14")
    producer = ndn.net['sensor14']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor15")
    producer = ndn.net['sensor15']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor16")
    producer = ndn.net['sensor16']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor17")
    producer = ndn.net['sensor17']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor18")
    producer = ndn.net['sensor18']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor19")
    producer = ndn.net['sensor19']
    producer.cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-producer {} {} > cabeee_producer.log &'.format(PREFIX, "/sensor20")
    producer = ndn.net['sensor20']
    producer.cmd(cmd)
    

    sleep(1)


    # SET UP THE SERVICES
    # run the cabeee-dag-serviceA-app application on all router nodes
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service1.log &'.format(PREFIX, "/serviceP1")
    ndn.net['rtr1'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service2.log &'.format(PREFIX, "/serviceP2")
    ndn.net['rtr2'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service3.log &'.format(PREFIX, "/serviceP3")
    ndn.net['rtr3'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service4.log &'.format(PREFIX, "/serviceP4")
    ndn.net['rtr4'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service5.log &'.format(PREFIX, "/serviceP5")
    ndn.net['rtr5'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service6.log &'.format(PREFIX, "/serviceP6")
    ndn.net['rtr6'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service7.log &'.format(PREFIX, "/serviceP7")
    ndn.net['rtr7'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service8.log &'.format(PREFIX, "/serviceP8")
    ndn.net['rtr8'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service9.log &'.format(PREFIX, "/serviceP9")
    ndn.net['rtr9'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service10.log &'.format(PREFIX, "/serviceP10")
    ndn.net['rtr10'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service11.log &'.format(PREFIX, "/serviceP11")
    ndn.net['rtr11'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service12.log &'.format(PREFIX, "/serviceP12")
    ndn.net['rtr12'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service13.log &'.format(PREFIX, "/serviceP13")
    ndn.net['rtr13'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service14.log &'.format(PREFIX, "/serviceP14")
    ndn.net['rtr14'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service15.log &'.format(PREFIX, "/serviceP15")
    ndn.net['rtr15'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service16.log &'.format(PREFIX, "/serviceP16")
    ndn.net['rtr16'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service17.log &'.format(PREFIX, "/serviceP17")
    ndn.net['rtr17'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service18.log &'.format(PREFIX, "/serviceP18")
    ndn.net['rtr18'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service19.log &'.format(PREFIX, "/serviceP19")
    ndn.net['rtr19'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service20.log &'.format(PREFIX, "/serviceP20")
    ndn.net['rtr20'].cmd(cmd)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-serviceA-app {} {} > cabeee_serviceA_service21.log &'.format(PREFIX, "/serviceP21")
    ndn.net['rtr21'].cmd(cmd)


    # SET UP THE ORCHESTRATOR
    # run the cabeee-dag-orchestratorA-app application on all router nodes
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-dag-orchestratorA-app {} {} > cabeee_orchestratorA.log &'.format(PREFIX, "/serviceOrchestration")
    ndn.net['orch'].cmd(cmd)

    # SET UP THE CONSUMER
    info('Starting Consumer App (after waiting one second for RIB updates to finish propagating)\n')
    sleep(1) # wait so that we don't start the consumer until all RIB updates have propagated
    # App input is the main PREFIX, the workflow file, and the orchestration value (0, 1 or 2)
    cmd = '/home/cabeee/mini-ndn/dl/ndn-cxx/build/examples/cabeee-custom-app-consumer {} {} {} > cabeee_consumer.log &'.format(PREFIX, WORKFLOW, 1)
    consumer = ndn.net['user']
    consumer.cmd(cmd)


    sleep(1)







    info("\nExperiment Completed!\n")
    MiniNDNCLI(ndn.net)
    ndn.stop()

    # concatenate every node's log/nfd.log file to a single one. Keep timestamp, add node name. Sort by timestamp!
    MergeNFDLogs.mergeAllLogs()

if __name__ == '__main__':
    setLogLevel("info")
    #setLogLevel("debug")
    run()