# Copyright (c) 2018 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
| Resource | resources/libraries/robot/performance/performance_setup.robot
| ...
| Force Tags | 2_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | MRR
| ... | NIC_Intel-X710 | ETH | IP6FWD | SCALE | FIB_200k
| ...
| Suite Setup | Set up 2-node performance topology with DUT's NIC model
| ... | L3 | Intel-X710
| Suite Teardown | Tear down 2-node performance topology
| ...
| Test Setup | Set up performance test
| ...
| Test Teardown | Tear down performance mrr test
| ...
| Test Template | Local Template
| ...
| Documentation | *Raw results IPv6 routing test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-TG 2-node circular topology with\
| ... | single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6 for IPv6 routing.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with IPv6 routing and\
| ... | 2x100k static IPv6 /64 route entries. DUT1 is tested with 2p10GE NIC\
| ... | X710 by Intel.
| ... | *[Ver] TG verification:* In MaxReceivedRate tests TG sends traffic\
| ... | at line rate and reports total received/sent packets over trial period.\
| ... | Test packets are generated by TG on links to DUT1. TG traffic profile\
| ... | contains two L3 flow-groups (flow-group per direction, 100k flows per\
| ... | flow-group) with all packets containing Ethernet header, IPv6 header\
| ... | with IP and static payload. MAC addresses are matching MAC addresses\
| ... | of the TG node interfaces. Incrementing of IP.dst (IPv6 destination\
| ... | address) field is applied to both streams.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# X710-DA2 bandwidth limit
| ${s_limit}= | ${10000000000}
| ${rts_per_flow}= | ${100000}
# Traffic profile:
| ${traffic_profile}= | trex-sl-2n-ethip6-ip6dst${rts_per_flow}

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 routing config.
| | ... | Each DUT uses ${phy_cores} physical core(s) for worker threads.
| | ... | [Ver] Measure MaxReceivedRate for ${framesize}B frames using single\
| | ... | trial throughput test.
| | ...
| | ... | *Arguments:*
| | ... | - framesize - Framesize in Bytes in integer or string (IMIX_v4_1).
| | ... | Type: integer, string
| | ... | - phy_cores - Number of physical cores. Type: integer
| | ... | - rxq - Number of RX queues, default value: ${None}. Type: integer
| | ...
| | [Arguments] | ${framesize} | ${phy_cores} | ${rxq}=${None}
| | ...
| | Given Add worker threads and rxqueues to all DUTs | ${phy_cores} | ${rxq}
| | And Add PCI devices to all DUTs
| | ${max_rate} | ${jumbo} = | Get Max Rate And Jumbo And Handle Multi Seg
| | ... | ${s_limit} | ${framesize}
| | And Apply startup configuration on all VPP DUTs
| | When Initialize IPv6 forwarding with scaling in circular topology
| | ... | ${rts_per_flow}
| | Then Traffic should pass with maximum rate
| | ... | ${max_rate}pps | ${framesize} | ${traffic_profile}

*** Test Cases ***
| tc01-78B-1c-ethip6-ip6scale200k-mrr
| | [Tags] | 78B | 1C
| | framesize=${78} | phy_cores=${1}

| tc02-78B-2c-ethip6-ip6scale200k-mrr
| | [Tags] | 78B | 2C
| | framesize=${78} | phy_cores=${2}

| tc03-78B-4c-ethip6-ip6scale200k-mrr
| | [Tags] | 78B | 4C
| | framesize=${78} | phy_cores=${4}

| tc04-1518B-1c-ethip6-ip6scale200k-mrr
| | [Tags] | 1518B | 1C
| | framesize=${1518} | phy_cores=${1}

| tc05-1518B-2c-ethip6-ip6scale200k-mrr
| | [Tags] | 1518B | 2C
| | framesize=${1518} | phy_cores=${2}

| tc06-1518B-4c-ethip6-ip6scale200k-mrr
| | [Tags] | 1518B | 4C
| | framesize=${1518} | phy_cores=${4}

| tc07-9000B-1c-ethip6-ip6scale200k-mrr
| | [Tags] | 9000B | 1C
| | framesize=${9000} | phy_cores=${1}

| tc08-9000B-2c-ethip6-ip6scale200k-mrr
| | [Tags] | 9000B | 2C
| | framesize=${9000} | phy_cores=${2}

| tc09-9000B-4c-ethip6-ip6scale200k-mrr
| | [Tags] | 9000B | 4C
| | framesize=${9000} | phy_cores=${4}

| tc10-IMIX-1c-ethip6-ip6scale200k-mrr
| | [Tags] | IMIX | 1C
| | framesize=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-ethip6-ip6scale200k-mrr
| | [Tags] | IMIX | 2C
| | framesize=IMIX_v4_1 | phy_cores=${2}

| tc12-IMIX-4c-ethip6-ip6scale200k-mrr
| | [Tags] | IMIX | 4C
| | framesize=IMIX_v4_1 | phy_cores=${4}
