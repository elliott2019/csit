Release Notes
=============

Changes in |csit-release|
-------------------------

#. VPP PERFORMANCE TESTS

   - **Intel Xeon 2n-skx, 3n-skx testbeds**: VPP performance test data
     is not included in this report version. This is due to the lower
     performance and behaviour inconsistency of these systems
     following the upgrade of processor microcode packages (skx ucode
     0x2000064), done as part of updating Ubuntu 18.04 LTS kernel
     version. Tested VPP and DPDK applications (L3fwd) are affected.
     Skx test data will be added in subsequent maintenance report
     version(s) once the issue is resolved. See
     :ref:`vpp_known_issues`.

   - **Intel Xeon 2n-clx testbeds**: VPP performance test data is now
     included in this report, after resolving the issue of lower
     performance and behaviour inconsistency of these systems due to
     the Linux kernel driven upgrade of processor microcode packages
     to 0x500002c. The resolution is to use latest SuperMicro BIOS 3.2
     (for X11DPG-QT motherboards used) that upgrades processor
     microcode to 0x500002c, AND NOT kernel provided ucode package as
     it does put system into sub-optimal state. Subset of 2n-clx VPP
     tests are failing due to clx system behaviour change:  i) all ip4
     tests with xxv710 and avf driver and ii) some cx556a rdma tests.
     See :ref:`vpp_known_issues`.

   - **Service density 2n-skx tests**: Added new NF density tests with
     IPsec encryption between DUTs.

   - **AVF tests**: Full test coveraged based on code changes in CSIT
     core layer (driver/interface awareness) and generated by suite
     generator (Intel Fortville NICs only).

   - **Hoststack tests**: Major refactor of VPP Hoststack TCP/IP
     performance tests using WRK generator talking to the VPP HTTP
     static server plugin measuring connections per second and
     requests per second. Added new iperf3 with LDPreload tests,
     iperf3/LDPreload tests with packet loss induced via the VPP NSIM
     (Network Simulator) plugin, and QUIC/UDP/IP transport tests.
     All of the new tests measure goodput through the VPP Hoststack
     from client to server.

   - **Latency HDRHistogram**: Added High Dynamic Range Histogram
     latency measurements based on the new capability in TRex traffic
     generator. HDRH latency data presented in latency packet
     percentile graphs and in detailed results tables.

   - **Mellanox CX556A-EDAT tests**: Added tests with Mellanox
     ConnectX5-2p100GE NICs in 2n-clx testbeds using VPP native rdma
     driver.

   - **IPsec reconfiguration tests**: Added tests measuring the impact
     of IPsec tunnels creations and removals.

   - **Load Balancer tests**: Added VPP performance tests for Maglev,
     L3DSR (Direct Server Return), Layer 4 Load Balancing NAT Mode.

#. TEST FRAMEWORK

   - **CSIT Python3 support**: Full migration of CSIT from Python2.7 to
     Python3.6. This change includes library migration, PIP dependency
     upgrade, CSIT container images, infrastructure packages
     ugrade/installation.

   - **CSIT PAPI support**: Finished conversion of CSIT VAT L1 keywords
     to PAPI L1 KWs in CSIT using VPP Python bindings (VPP PAPI).
     Redesign of key components of PAPI Socket Executor and PAPI
     history. Due to issues with PAPI performance, VAT is still used
     in CSIT for all VPP scale tests. See known issues below.

   - **Test Suite Generator**: Added capability to generate suites for
     different drivers per NIC model including DPDK, AVF, RDMA.
     Extended coverage for all tests.

   - **General Code Housekeeping**: Ongoing RF keywords optimizations,
     removal of redundant RF keywords and aligning of suite/test
     setup/teardowns.

#. TEST ENVIRONMENT

   - **TRex Fortville NIC Performance**: Received FVL fix from Intel
     resolving TRex low throughput issue. TRex per FVL NIC throughput
     increased from ~27 Mpps to the nominal ~37 Mpps. For detail see
     `CSIT-1503 <https://jira.fd.io/browse/CSIT-1503>`_ and `TRex-519
     <https://trex-tgn.cisco.com/youtrack/issue/trex-519>`_].

   - **New Intel Xeon Cascadelake Testbeds**: Added performance tests
     for 2-Node-Cascadelake (2n-clx) testbeds with x710, xxv710 and
     cx556a-edat NIC cards.

#. PRESENTATION AND ANALYTICS LAYER

   - **Graphs layout improvements**: Improved performance graphs layout
     for better readibility and maintenance: test grouping, axis
     labels, descriptions, other informative decoration.

   - **Latency graphs**: Min/Avg/Max group bar latency graphs are
     replaced with packet latency percentile distributon at different
     background packet loads based on TRex latency hdrhistogram
     measurements.

..
    // Alternative Note for 1st Bullet when bad microcode Skx, Clx results are published
    - **Intel Xeon 2n-skx, 3n-skx and 2n-clx testbeds**: VPP performance
      test data is included in this report version, but it shows lower
      performance and behaviour inconsistency of these systems
      following the upgrade of processor microcode packages (skx ucode
      0x2000064, clx ucode 0x500002c) as part of updating Ubuntu 18.04
      LTS kernel version. Tested VPP and DPDK applications (L3fwd) are
      affected. Skx and Clx test data will be corrected in subsequent
      maintenance report version(s) once the issue is resolved. See
      :ref:`vpp_known_issues`.

.. raw:: latex

    \clearpage

.. _vpp_known_issues:

Known Issues
------------

List of known issues in |csit-release| for VPP performance tests:

+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| #  | JiraID                                  | Issue Description                                                                                         |
+====+=========================================+===========================================================================================================+
| 1  | `CSIT-570                               | Sporadic (1 in 200) NDR discovery test failures on x520. DPDK reporting rx-errors, indicating L1 issue.   |
|    | <https://jira.fd.io/browse/CSIT-570>`_  | Suspected issue with HW combination of X710-X520 in LF testbeds. Not observed outside of LF testbeds.     |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 2  | `VPP-662                                | 9000B packets not supported by NICs VIC1227 and VIC1387.                                                  |
|    | <https://jira.fd.io/browse/VPP-662>`_   |                                                                                                           |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 3  | `CSIT-1498                              | Memif tests are sporadically failing on initialization of memif connection.                               |
|    | <https://jira.fd.io/browse/CSIT-1498>`_ |                                                                                                           |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 4  | `VPP-1677                               | 9000B ip4 nat44: VPP crash + coredump.                                                                    |
|    | <https://jira.fd.io/browse/VPP-1677>`_  | VPP crashes very often in case that NAT44 is configured and it has to process IP4 jumbo frames (9000B).   |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 5  | `CSIT-1591                              | All CSIT scale tests can not use PAPI due to much slower performance compared to VAT/CLI (it takes much   |
|    | <https://jira.fd.io/browse/CSIT-1499>`_ | longer to program VPP). This needs to be addressed on the PAPI side.                                      |
|    +-----------------------------------------+                                                                                                           |
|    | `VPP-1763                               |                                                                                                           |
|    | <https://jira.fd.io/browse/VPP-1763>`_  |                                                                                                           |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 6  | `VPP-1675                               | IPv4 IPSEC 9000B packet tests are failing as no packet is forwarded.                                      |
|    | <https://jira.fd.io/browse/VPP-1675>`_  | Reason: chained buffers are not supported.                                                                |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 7  | `CSIT-1593                              | IPv4 AVF 9000B packet tests are failing on 3n-skx while passing on 2n-skx.                                |
|    | <https://jira.fd.io/browse/CSIT-1593>`_ |                                                                                                           |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 8  | `CSIT-1675                              | Intel Xeon 2n-skx, 3n-skx and 2n-clx testbeds behaviour and performance became inconsistent following     |
|    | <https://jira.fd.io/browse/CSIT-1675>`_ | the upgrade to the latest Ubuntu 18.04 LTS kernel version (4.15.0-72-generic) and associated microcode    |
|    |                                         | packages (skx ucode 0x2000064, clx ucode 0x500002c). VPP as well as DPDK L3fwd tests are affected.        |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 9  | `CSIT-1679                              | All 2n-clx VPP ip4 tests with xxv710 and avf driver are failing.                                          |
|    | <https://jira.fd.io/browse/CSIT-1679>`_ |                                                                                                           |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
| 10 | `CSIT-1680                              | Some 2n-clx cx556a rdma tests are failing.                                                                |
|    | <https://jira.fd.io/browse/CSIT-1680>`_ |                                                                                                           |
+----+-----------------------------------------+-----------------------------------------------------------------------------------------------------------+
