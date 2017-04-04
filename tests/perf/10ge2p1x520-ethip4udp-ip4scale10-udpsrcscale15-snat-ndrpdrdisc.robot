# Copyright (c) 2017 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/performance.robot
| Resource | resources/libraries/robot/snat.robot
| Resource | resources/libraries/robot/traffic.robot
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | ETH | IP4FWD | FEATURE | SNAT | SRC_USER_10
| ... | SCALE
| ...
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| ...
| Test Setup | Performance test setup
| ...
| Documentation | *SNAT performance test cases*
| ...
| ... | *High level description*
| ...
| ... | - NDR and PDR tests
| ... | - 3-node topology, TG-DUT1-DUT2-TG, SNAT is enabled between DUTs.
| ... | - Cores / threads: 1t1c and 2t2c
| ... | - Framesize: 64B, 1518B, IMIX
| ... | - Packet: ETH / IP(src, dst) / UDP(src_port, dst_port) / payload
| ... | - scale: src: 1 user, 10 users, 100 users, ..., 4000 up to the memory
| ... |   limit; 15 ports per user
| ...
| ... | *Low level description*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4-UDP for IPv4 routing.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv4
| ... | routing and two static IPv4 /24 and IPv4/20 route entries. DUT1 and DUT2
| ... | tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage
| ... | of packets transmitted. NDR and PDR are discovered for different
| ... | Ethernet L2 frame sizes using either binary search or linear search
| ... | algorithms with configured starting rate and final step that determines
| ... | throughput measurement resolution. Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, one flow per flow-group) with all packets
| ... | containing Ethernet header, IPv4 header with UDP header and static
| ... | payload. MAC addresses are matching MAC addresses of the TG node
| ... | interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# X520-DA2 bandwidth limit
| ${s_limit} | ${10000000000}
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4udp-10u15p

*** Test Cases ***
| tc01-64B-1t1c-ethip4udp-ip4scale10-udpsrcscale15-snat-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port. SNAT is configured between DUTs -\
| | ... | 10 users and 15 ports (sessions) per user.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Teardown] | Run keywords | Performance test teardown | ${min_rate}pps
| | ... | ${framesize} | ${traffic_profile}
| | ... | AND | Show SNAT verbose | ${dut1}
| | ... | AND | Show SNAT verbose | ${dut2}
| | ...
| | [Tags] | 64B | 1T1C | STHREAD | NDRDISC
| | ...
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Add No Multi Seg to all DUTs
| | And Add SNAT to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When SNAT is initialized in a 3-node circular topology
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ... | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc02-64B-1t1c-ethip4udp-ip4scale10-udpsrcscale15-snat-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port. SNAT is configured between DUTs -\
| | ... | 10 users and 15 ports (sessions) per user.
| | ... | [Ver] Find PDR for 64 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Teardown] | Performance test teardown | ${min_rate}pps | ${framesize}
| | ... | ${traffic_profile}
| | ...
| | [Tags] | 64B | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ...
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Add No Multi Seg to all DUTs
| | And Add SNAT to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When SNAT is initialized in a 3-node circular topology
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ... | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold} | ${perf_pdr_loss_acceptance}
| | ... | ${perf_pdr_loss_acceptance_type}

| tc03-1518B-1t1c-ethip4udp-ip4scale10-udpsrcscale15-snat-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port. SNAT is configured between DUTs -\
| | ... | 10 users and 15 ports (sessions) per user.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Teardown] | Run keywords | Performance test teardown | ${min_rate}pps
| | ... | ${framesize} | ${traffic_profile}
| | ... | AND | Show SNAT verbose | ${dut1}
| | ... | AND | Show SNAT verbose | ${dut2}
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD | NDRDISC
| | ...
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Add No Multi Seg to all DUTs
| | And Add SNAT to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When SNAT is initialized in a 3-node circular topology
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ... | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc04-1518B-1t1c-ethip4udp-ip4scale10-udpsrcscale15-snat-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port. SNAT is configured between DUTs -\
| | ... | 10 users and 15 ports (sessions) per user.
| | ... | [Ver] Find PDR for 1518 Byte frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Teardown] | Performance test teardown | ${min_rate}pps | ${framesize}
| | ... | ${traffic_profile}
| | ...
| | [Tags] | 1518B | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ...
| | ${framesize}= | Set Variable | ${1518}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Add No Multi Seg to all DUTs
| | And Add SNAT to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When SNAT is initialized in a 3-node circular topology
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ... | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold} | ${perf_pdr_loss_acceptance}
| | ... | ${perf_pdr_loss_acceptance_type}

| tc05-IMIX-1t1c-ethip4udp-ip4scale10-udpsrcscale15-snat-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port. SNAT is configured between DUTs -\
| | ... | 10 users and 15 ports (sessions) per user.
| | ... | [Ver] Find NDR for IMIX frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Teardown] | Run keywords | Performance test teardown | ${min_rate}pps
| | ... | ${framesize} | ${traffic_profile}
| | ... | AND | Show SNAT verbose | ${dut1}
| | ... | AND | Show SNAT verbose | ${dut2}
| | ...
| | [Tags] | IMIX | 1T1C | STHREAD | NDRDISC
| | ...
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Add No Multi Seg to all DUTs
| | And Add SNAT to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When SNAT is initialized in a 3-node circular topology
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ... | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}

| tc06-IMIX-1t1c-ethip4udp-ip4scale10-udpsrcscale15-snat-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port. SNAT is configured between DUTs -\
| | ... | 10 users and 15 ports (sessions) per user.
| | ... | [Ver] Find PDR for IMIX frames using binary search start at 10GE\
| | ... | linerate, step 100kpps.
| | ...
| | [Teardown] | Performance test teardown | ${min_rate}pps | ${framesize}
| | ... | ${traffic_profile}
| | ...
| | [Tags] | IMIX | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ...
| | ${framesize}= | Set Variable | IMIX_v4_1
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And Add PCI devices to DUTs from 3-node single link topology
| | And Add No Multi Seg to all DUTs
| | And Add SNAT to all DUTs
| | And Apply startup configuration on all VPP DUTs
| | When SNAT is initialized in a 3-node circular topology
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ... | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold} | ${perf_pdr_loss_acceptance}
| | ... | ${perf_pdr_loss_acceptance_type}
