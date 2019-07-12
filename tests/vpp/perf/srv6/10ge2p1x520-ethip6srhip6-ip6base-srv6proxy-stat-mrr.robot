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
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | MRR
| ... | NIC_Intel-X520-DA2 | SRv6 | IP6FWD | FEATURE | SRv6_PROXY
| ... | SRv6_PROXY_STAT | MEMIF | LXC
| ...
| Suite Setup | Run Keywords
| ... | Set up 3-node performance topology with DUT's NIC model | L3
| ... | Intel-X520-DA2
| ... | AND | Set up performance test suite with MEMIF
| ... | AND | Set up performance test suite with Static SRv6 proxy
| ...
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| ...
| Test Teardown | Run Keywords
| ... | Tear down mrr test with SRv6 with encapsulation
| ... | AND | Tear down performance test with container
| ...
| Test Template | Local template
| ...
| Documentation | *Packet throughput Segment routing over IPv6 dataplane with\
| ... | Static SRv6 proxy test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6-SRH-IPv6 on DUT1-DUT2 and\
| ... | DUTn->TG, Eth-IPv6 on TG->DUTn and DUTn-LXC for IPv6 routing over SRv6.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv6\
| ... | routing and static route, SR policy and steering policy for one\
| ... | direction and one SR behaviour (function) - End.AS - for other\
| ... | direction. DUT1 and DUT2 are tested with 2p10GE NIC X520 Niantic\
| ... | by Intel.
| ... | *[Ver] TG verification:* In MaxReceivedRate tests TG sends traffic\
| ... | at line rate and reports total received/sent packets over trial period.\
| ... | Test packets are generated by TG on\
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups\
| ... | (flow-group per direction, 253 flows per flow-group) with\
| ... | all packets containing Ethernet header,IPv6 header with static payload.\
| ... | MAC addresses are matching MAC addresses of the TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* SRv6 Network Programming -\
| ... | draft 3 and Segment Routing for Service Chaining - internet draft 01.

*** Variables ***
# X520-DA2 bandwidth limit
| ${s_limit}= | ${10000000000}
# SIDs
| ${dut1_sid1}= | 2002:1::
| ${dut1_sid2}= | 2003:2::
| ${dut1_bsid}= | 2002:1::1
| ${dut2_sid1}= | 2002:2::
| ${dut2_sid2}= | 2003:1::
| ${dut2_bsid}= | 2003:1::1
| ${out_sid1_1}= | 2002:3::
| ${out_sid1_2}= | 2002:4::
| ${out_sid2_1}= | 2003:3::
| ${out_sid2_2}= | 2003:4::
| ${sid_prefix}= | ${64}
# IP settings
| ${tg_if1_ip6_subnet}= | 2001:1::
| ${tg_if2_ip6_subnet}= | 2001:2::
| ${dut1_if1_ip6}= | 2001:1::1
| ${dut1_if2_ip6}= | 2001:3::1
| ${dut1-memif-1-if1_ip6}= | 3001:1::1
| ${dut1-memif-1-if2_ip6}= | 3001:1::2
| ${dut1_nh}= | 4002::
| ${dut2_if1_ip6}= | 2001:3::2
| ${dut2_if2_ip6}= | 2001:2::1
| ${dut2-memif-1-if1_ip6}= | 3002:1::1
| ${dut2-memif-1-if2_ip6}= | 3002:1::2
| ${dut2_nh}= | 4001::
| ${prefix}= | ${64}
# outer IPv6 header + SRH with 3 SIDs: 40+(8+3*16)B
| ${srv6_overhead_3sids}= | ${96}
# Traffic profile:
| ${traffic_profile}= | trex-sl-3n-ethip6-ip6src253
# Container
| ${container_engine}= | LXC
| ${container_chain_topology}= | chain

*** Keywords ***
| Local template
| | [Documentation]
| | ... | [Cfg] DUT runs IPv6 over SRv6 routing config with ${phy_cores} phy
| | ... | core(s).
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
| | ... | ${s_limit} | ${framesize} | overhead=${srv6_overhead_3sids}
| | And Apply startup configuration on all VPP DUTs
| | And Set up performance test with containers | nf_chains=${1} | nf_nodes=${1}
| | When Initialize IPv6 forwarding over SRv6 with endpoint to SR-unaware Service Function via 'static_proxy' behaviour in 3-node circular topology
| | Then Traffic should pass with maximum rate
| | ... | ${max_rate}pps | ${framesize} | ${traffic_profile}

*** Test Cases ***
| tc01-78B-1c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 78B | 1C
| | framesize=${78} | phy_cores=${1}

| tc02-78B-2c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 78B | 2C
| | framesize=${78} | phy_cores=${2}

| tc03-78B-4c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 78B | 4C
| | framesize=${78} | phy_cores=${4}

| tc04-1518B-1c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 1518B | 1C
| | framesize=${1518} | phy_cores=${1}

| tc05-1518B-2c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 1518B | 2C
| | framesize=${1518} | phy_cores=${2}

| tc06-1518B-4c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 1518B | 4C
| | framesize=${1518} | phy_cores=${4}

| tc07-9000B-1c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 9000B | 1C
| | framesize=${9000} | phy_cores=${1}

| tc08-9000B-2c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 9000B | 2C
| | framesize=${9000} | phy_cores=${2}

| tc09-9000B-4c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | 9000B | 4C
| | framesize=${9000} | phy_cores=${4}

| tc10-IMIX-1c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | IMIX | 1C
| | framesize=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | IMIX | 2C
| | framesize=IMIX_v4_1 | phy_cores=${2}

| tc12-IMIX-4c-ethip6srhip6-ip6base-srv6proxy-stat-mrr
| | [Tags] | IMIX | 4C
| | framesize=IMIX_v4_1 | phy_cores=${4}