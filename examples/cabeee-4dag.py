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

from subprocess import PIPE

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

PREFIX = "/example"

def printOutput(output):
    _out = output.decode("utf-8").split("\n")
    for _line in _out:
        info(_line + "\n")

def run():
    Minindn.cleanUp()
    Minindn.verifyDependencies()

    MergeNFDLogs.deleteAllLogs()

    # the following parser came from static_routing_experiment.py
    parser = argparse.ArgumentParser()
    parser.add_argument('--face-type', dest='faceType', default='udp', choices=['udp', 'tcp'])
    parser.add_argument('--routing', dest='routingType', default='link-state',
                         choices=['link-state', 'hr', 'dry'],
                         help='''Choose routing type, dry = link-state is used
                                 but hr is calculated for comparision.''')



    '''
    # Topology can be created/modified using Mininet topo object
    topo = Topo()
    info("Setup\n")
    # add hosts
    a = topo.addHost('a')
    b = topo.addHost('b')
    c = topo.addHost('c')

    # add links
    topo.addLink(a, b, delay='10ms', bw=10) # bw = bandwidth
    topo.addLink(b, c, delay='10ms', bw=10)
    '''

    ndn = Minindn(parser=parser, topoFile='topologies/cabeee-3node.conf')
    #ndn = Minindn(parser=parser, topoFile='topologies/cabeee-3node-slow.conf')
    #ndn = Minindn(topoFile='topologies/cabeee-default-topology.conf')
    ndn.start()

    # configure and start nfd on each node
    info("Configuring NFD\n")
    AppManager(ndn, ndn.net.hosts, Nfd, logLevel="DEBUG")



    routeOption = 2

    """
    There are multiple ways of setting up routes in Mini-NDN
    refer: https://minindn.memphis.edu/experiment.html#routing-options
    """

    if routeOption == 1:
        # OPTION 1
        # set up routes manually. The important bit to note here is the use of the Nfdc command
        info('Setting up routes manually in NFD\n')
        #links = {"sensor":["rtr1"], "rtr1":["rtr2"], "rtr2":["rtr3"], "rtr3":["orch"], "orch":["user"]} # routes are directional! This is the wrong direction.
        links = {"user":["orch"], "orch":["rtr3"], "rtr3":["rtr2"], "rtr2":["rtr1"], "rtr1":["sensor"]}
        for first in links:
            for second in links[first]:
                host1 = ndn.net[first]
                host2 = ndn.net[second]
                interface = host2.connectionsTo(host1)[0][0]
                interface_ip = interface.IP()
                Nfdc.createFace(host1, interface_ip)
                Nfdc.registerRoute(host1, PREFIX, interface_ip, cost=0)

    if routeOption == 2:
        # OPTION 2
        # or use static routing as used in static_routing_experiment.py
        info('Adding static routes to NFD\n')
        grh = NdnRoutingHelper(ndn.net, ndn.args.faceType, ndn.args.routingType)
        # For all host, pass ndn.net.hosts or a list, [ndn.net['a'], ..] or [ndn.net.hosts[0],.]
        grh.addOrigin([ndn.net['sensor']], [PREFIX])
        grh.calculateNPossibleRoutes()
        #PREFIX is advertised from node A, it should be reachable from all other nodes.
        routesFromSensor = ndn.net['sensor'].cmd("nfdc route | grep -v '/localhost/nfd'")
        if '/ndn/rtr1-site/rtr1' not in routesFromSensor or \
           '/ndn/rtr2-site/rtr2' not in routesFromSensor or \
           '/ndn/rtr3-site/rtr3' not in routesFromSensor or \
           '/ndn/orch-site/orch' not in routesFromSensor or \
           '/ndn/user-site/user' not in routesFromSensor:
            info("Route addition failed\n")
        routesToPrefix = ndn.net['rtr1'].cmd("nfdc fib | grep '/example'")
        if '/example' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['rtr2'].cmd("nfdc fib | grep '/example'")
        if '/example' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['rtr3'].cmd("nfdc fib | grep '/example'")
        if '/example' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        routesToPrefix = ndn.net['orch'].cmd("nfdc fib | grep '/example'")
        if '/example' not in routesToPrefix:
            info("Missing route to advertised prefix, Route addition failed\n")
            ndn.net.stop()
            sys.exit(1)
        info('Route addition to NFD completed\n')



    if routeOption == 3:
        # OPTION 3
        # or use IP routing as used in ip_rounting_experiment.py
        # NOTE: this will only work if we send pings based on IP address (as done in
        # dl/mininet/mininet/net.py ping function)
        info('Adding IP routes to NFD\n')
        #info('Starting NFD on nodes\n')
        #nfds = AppManager(ndn, ndn.net.hosts, Nfd)
        info('Starting NLSR on nodes\n')
        nlsrs = AppManager(ndn, ndn.net.hosts, Nlsr)

        # Calculate all routes for IP routing
        IPRoutingHelper.calcAllRoutes(ndn.net)
        info("IP routes configured, start ping\n")





    # Start ping server
    info("Starting pings...\n")
    pingserver_log = open("{}/sensor/ndnpingserver.log".format(ndn.workDir), "w")
    getPopen(ndn.net["sensor"], "ndnpingserver {}".format(PREFIX), stdout=pingserver_log,\
             stderr=pingserver_log)

    # start ping client
    ping1 = getPopen(ndn.net["user"], "ndnping {} -c 5".format(PREFIX), stdout=PIPE, stderr=PIPE)
    ping1.wait()
    printOutput(ping1.stdout.read())

    '''
    interface = ndn.net["rtr3"].connectionsTo(ndn.net["rtr2"])[0][0]
    info("Failing link\n") # failing link by setting link loss to 100%
    interface.config(delay="10ms", bw=10, loss=100)
    info ("\n starting ping2 client \n")

    ping2 = getPopen(ndn.net["user"], "ndnping {} -c 5".format(PREFIX), stdout=PIPE, stderr=PIPE)
    ping2.wait()
    printOutput(ping2.stdout.read())

    interface.config(delay="10ms", bw=10, loss=0) # bringing back the link
    '''

    # concatenate every node's log/nfd.log file to a single one. Keep timestamp, add node name. Sort by timestamp!
    MergeNFDLogs.mergeAllLogs()

    info("\nExperiment Completed!\n")
    MiniNDNCLI(ndn.net)
    ndn.stop()

if __name__ == '__main__':
    setLogLevel("info")
    #setLogLevel("debug")
    run()