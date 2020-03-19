# Presentation and Analytics Layer

Presentation and Analytics Layer (PAL) makes possible to present and
analyse the test results generated by CSIT Jenkins jobs.

## Using PAL in the Local mode

The local mode makes possible to use:
1. a single XML file,
2. a directory with XML files, or
3. a directory with directories of XML files.

### Using a single XML file

Run the script with the path to a local XML file, e.g.:

    ./run_local_report.sh --file output.xml

### Using a directory of XML files

Store all XML files in a directory, e.g.:

    csit-vpp-perf-verify-2001-3n-dnv/
    ├── csit-vpp-perf-verify-2001-3n-dnv__5__output_info.xml
    ├── csit-vpp-perf-verify-2001-3n-dnv__6__output_info.xml
    └── csit-vpp-perf-verify-2001-3n-dnv__7__output_info.xml

and use:

    ./run_local_report.sh --directory csit-vpp-perf-verify-2001-3n-dnv/

### Using a directory with directories of XML files.

Store all XML files in a directory structure, e.g.:

    local/
    ├── csit-vpp-perf-verify-2001-2n-clx
    │   ├── csit-vpp-perf-verify-2001-2n-clx__28__output_info.xml
    │   └── csit-vpp-perf-verify-2001-2n-clx__29__output_info.xml
    └── csit-vpp-perf-verify-2001-3n-dnv
        ├── csit-vpp-perf-verify-2001-3n-dnv__5__output_info.xml
        ├── csit-vpp-perf-verify-2001-3n-dnv__6__output_info.xml
        └── csit-vpp-perf-verify-2001-3n-dnv__7__output_info.xml

and use:

    ./run_local_report.sh --directory local/

### Example

For more information and for a running example see the specificaton file
`specification_local.yaml`.