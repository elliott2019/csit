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
| Resource | resources/libraries/robot/tagging.robot
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-X520-DA2 | L2XCFWD | BASE | DOT1AD
| ...
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| ...
| Test Setup | Performance test setup
| Test Teardown | Performance test teardown | ${min_rate}pps | ${framesize}
| ... | 3-node-xconnect
| ...
| Documentation | *RFC2544: Pkt throughput L2XC with 802.1ad test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 xconnect.
| ... | 802.1ad tagging is applied on link between DUT1 and DUT2 with inner 4B
| ... | vlan tag (id=100) and outer 4B vlan tag (id=200).
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 cross-
| ... | connect. DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage
| ... | of packets transmitted. NDR and PDR are discovered for different
| ... | Ethernet L2 frame sizes using either binary search or linear search
| ... | algorithms with configured starting rate and final step that determines
| ... | throughput measurement resolution. Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, 253 flows per flow-group) with all packets
| ... | containing Ethernet header, IPv4 header with IP protocol=61 and
| ... | static payload. MAC addresses are matching MAC addresses of the TG
| ... | node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
| ${subid}= | 10
| ${outer_vlan_id}= | 100
| ${inner_vlan_id}= | 200
| ${type_subif}= | two_tags
| ${tag_rewrite}= | pop-2
# X520-DA2 bandwidth limit
| ${s_limit} | ${10000000000}

*** Test Cases ***
| tc01-64B-1t1c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 64 Byte frames
| | ... | using binary search start at 10GE linerate, step 100kpps.
| | [Tags] | 1T1C | STHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc02-64B-1t1c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 64 Byte frames
| | ... | using binary search start at 10GE linerate, step 100kpps, LT=0.5%.
| | [Tags] | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc03-1514B-1t1c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 1514 Byte frames
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 1T1C | STHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${1514}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc04-1514B-1t1c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 1514 Byte frames
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1514}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc05-9000B-1t1c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 9000 Byte frames
| | ... | using binary search start at 10GE linerate, step 5kpps.
| | [Tags] | 1T1C | STHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${9000}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc06-9000B-1t1c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 9000 Byte frames
| | ... | using binary search start at 10GE linerate, step 5kpps, LT=0.5%.
| | [Tags] | 1T1C | STHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${9000}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc07-64B-2t2c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 64 Byte frames
| | ... | using binary search start at 10GE linerate, step 100kpps.
| | [Tags] | 2T2C | MTHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc08-64B-2t2c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 64 Byte frames
| | ... | using binary search start at 10GE linerate, step 100kpps, LT=0.5%.
| | [Tags] | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc09-1514B-2t2c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 1514 Byte frames
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 2T2C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1514}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc10-1514B-2t2c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 1514 Byte frames
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1514}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc11-9000B-2t2c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find NDR for 9000 Byte frames
| | ... | using binary search start at 10GE linerate, step 5kpps.
| | [Tags] | 2T2C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${9000}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc12-9000B-2t2c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Find PDR for 9000 Byte frames
| | ... | using binary search start at 10GE linerate, step 5kpps, LT=0.5%.
| | [Tags] | 2T2C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${9000}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc13-64B-4t4c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find NDR for 64 Byte frames
| | ... | using binary search start at 10GE linerate, step 100kpps.
| | [Tags] | 4T4C | MTHREAD | NDRDISC
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc14-64B-4t4c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find PDR for 64 Byte frames
| | ... | using binary search start at 10GE linerate, step 100kpps, LT=0.5%.
| | [Tags] | 4T4C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${64}
| | ${min_rate}= | Set Variable | ${100000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc15-1514B-4t4c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find NDR for 1514 Byte frames
| | ... | using binary search start at 10GE linerate, step 10kpps.
| | [Tags] | 4T4C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1514}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc16-1514B-4t4c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find PDR for 1514 Byte frames
| | ... | using binary search start at 10GE linerate, step 10kpps, LT=0.5%.
| | [Tags] | 4T4C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${1514}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}

| tc17-9000B-4t4c-dot1ad-l2xcbase-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find NDR for 9000 Byte frames
| | ... | using binary search start at 10GE linerate, step 5kpps.
| | [Tags] | 4T4C | MTHREAD | NDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${9000}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| tc18-9000B-4t4c-dot1ad-l2xcbase-pdrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2XC forwarding config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Find PDR for 9000 Byte frames
| | ... | using binary search start at 10GE linerate, step 5kpps, LT=0.5%.
| | [Tags] | 4T4C | MTHREAD | PDRDISC | SKIP_PATCH
| | ${framesize}= | Set Variable | ${9000}
| | ${min_rate}= | Set Variable | ${10000}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize + 8}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | And   VPP interfaces in path are up in a 3-node circular topology
| | When VLAN subinterfaces initialized on 3-node topology
| | ... | ${dut1} | ${dut1_if2} | ${dut2} | ${dut2_if1} | ${subid}
| | ... | ${outer_vlan_id} | ${inner_vlan_id} | ${type_subif}
| | And L2 tag rewrite method setup on interfaces
| | ... | ${dut1} | ${subif_index_1} | ${dut2} | ${subif_index_2}
| | ... | ${tag_rewrite}
| | And Interfaces and VLAN sub-interfaces inter-connected using L2-xconnect
| | ... | ${dut1} | ${dut1_if1} | ${subif_index_1}
| | ... | ${dut2} | ${dut2_if2} | ${subif_index_2}
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-xconnect
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${perf_pdr_loss_acceptance}
| | ...                                       | ${perf_pdr_loss_acceptance_type}
