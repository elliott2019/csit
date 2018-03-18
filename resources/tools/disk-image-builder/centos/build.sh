#!/bin/bash -e

# Copyright (c) 2016 Cisco and/or its affiliates.
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

# Purpose of this script is to build a VirtualBox or QCOW2 disk image
# for use with CSIT testing.
#
# As input parameters, the script takes:
#
# - A base Linux distribution (currently, only "ubuntu-14.04.4" is
#   supported),
# - A release timestamp in the format "YYYY-MM-DD" eg. "2016-05-21".
#   This timestamp MUST reference to a list of packages (APT, PIP)
#   that was previously generated by the "listmaker" VM and script.
# - A path to the nested VM image.
#
# The bullk of the work is done by packer,
# while this script does some of the pre- and post-processing.
# Steps executed are:
#
# 1.) Determine if building a QCOW or VirtualBox image. Currently,
#     we build a QCOW image if VIRL_* environment variables are
#     present (and we therefore assume we are building for VIRL),
#     or VirtualBox otherwise.
#
# 2.) Download packer, if not already installed.
#
# 3.) Download APT and PIP packages as required for the image.
#     We're downloading them here, rather than letting the VM
#     download them off the public internet, for two reasons:
#     a.) This allows us to keep and cache packets between runs
#         and download them only once,
#     b.) This means only the build host needs a working proxy
#         configuration and we do not need to worry about setting
#         a proxy inside the VM.
#
# 4.) Link the nested VM image into the main VM's temp directory
#
# 5.) Create Version and Changelog files
#
# 6.) Run Packer. Packer, in turn, will:
#     6.1.) Download the Operating System ISO image,
#     6.2.) Start a VM using the selected hypervisor (VirtualBox or Qemu),
#     6.3.) Boot the VM using the ISO image and send initial keystrokes
#           to initiate installation using a Preseed or Kickstart file,
#     6.4.) Drive the installation using until the point the VM is reachable
#           over SSH,
#     6.5.) Copy the temporary directory populated in steps 3-5 above to the VM,
#     6.6.) Run a script on the VM that performs post-installation:
#           6.6.1.) Install selected .deb packages
#           6.6.2.) Install PIP packages as per requirements.txt file
#           6.6.3.) Install nested VM image and VERSION/CHANGELOG files
#     6.7.) Run a script on VM that creates a Vagrant user (VirtualBox only)
#     6.8.) Run a script on VM that performs clean-up:
#           6.8.1.) Remove any temporary files created,
#           6.8.2.) Remove SSH host-keys
#           6.8.3.) Remove root user password
#           6.8.4.) Shut down the VM
#     6.9.) [TODO]: Upload the image to VIRL (QCOW only), -or-
#           Convert the image into a Vagrant box (VirtualBox only), and
#           [TODO/FIX]: Upload the Vagrant box to Atlas (VirtualBox only)
#
# 7.) Clean up

###
### 0. Set constants and verify parameters.
###
cd $(dirname $0)
BUILD_DIR="$(pwd)/build"
PACKER_DIR="${BUILD_DIR}/packer"

RPM_CACHE_DIR="${BUILD_DIR}/cache/rpm"
PIP_CACHE_DIR="${BUILD_DIR}/cache/pip"

PACKER_TEMPLATE="centos-7.3-1611.json"
LISTS_DIR="$(dirname $0)/lists"

function syntax {
  echo 'Syntax: $0 <Operating System> <Release> <Nested VM image>'
  echo
  echo '<Operating System>: Base distro, eg. ubuntu-14.04.4'
  echo '<Release>:          Release timestamp, eg. 2016-05-21'
  echo '<Nested VM image>:  Path to nested VM image'

  exit 1
}

## Parse command line options

OS=$1
RELDATE=$2
NESTED_IMG=$3

if [ "$3" = "" ]
then
  syntax
fi

## Identify version by looking at topmost version statement in CHANGELOG

VERSION=$(cat $(dirname $0)/CHANGELOG  | grep '^## ' | head -1 | \
  sed -e 's/.*\[\(.*\)\].*/\1/')
if [ "${VERSION}" = "" ]
then
  echo "Unable to determine build version from CHANGELOG file. Make sure"
  echo "that there is an entry for the most recent version in CHANGELOG,"
  echo "and that the entry is formated like"
  echo
  echo "## [1.0] - 2016-05-20"
  exit 1
fi
RELEASE="csit-${OS}_${RELDATE}_${VERSION}"

OUTPUT_DIR="${BUILD_DIR}/output/${RELEASE}"
LIST="${LISTS_DIR}/${OS}_${RELDATE}_${VERSION}"

if [ ! -d "${LIST}" ]
then
  echo "${LIST} not found"
  syntax
  exit 1
fi
if [ ! -f $NESTED_IMG ]
then
  echo "Nested image $NESTED_IMG not found"
  syntax
  exit 1
fi

ATLAS_RELDATE=${RELDATE//-}
ATLAS_VERSION="${ATLAS_RELDATE}.${VERSION}"

# Find an MD5 checksum utility

MD5UTIL=$(which md5sum) || MD5UTIL=$(which md5)
if [ $? -ne 0 ]
then
  echo "No MD5 utility found."
  echo "Please make sure you either have \"md5sum\" or \"md5\" installed."
  exit 1
fi

###
### 1. Determine build target.
###
if [ "$VIRL_USER" = "" ] || [ "$VIRL_PASSWORD" = "" ]
then
  OUTPUT_PROVIDER="virtualbox"
else
  OUTPUT_PROVIDER="qemu"
fi

echo "Building version $VERSION for ${OUTPUT_PROVIDER}"
echo "Release ${RELEASE}"
echo "Using Nested VM image: ${NESTED_IMG}"
echo


###
### 2. Download and extract packer, if not already installed
###
packer_os=$(uname -s)
if [ "$packer_os" = "Darwin" ]
then
  packer_url="https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_darwin_amd64.zip"
elif [ "$packer_os" = "Linux" ]
then
  packer_url="https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip"
fi

mkdir -p $BUILD_DIR
wget -P ${PACKER_DIR} -N ${packer_url}

unzip -n ${PACKER_DIR}/packer*zip -d ${PACKER_DIR}

###
### 3. Download RPM and PIP packages, and cache them
###    Verify downloaded RPM packages.
###    Link required packages into a temp directory for the VM image.
###


rm -fr ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}/temp/rpm
mkdir -p ${RPM_CACHE_DIR}

RPM_FILE="${LIST}/rpm-packages.txt"
###
### Copy rpm package list to cache dir because we are going to use yum on the image
###
echo cp $RPM_FILE ${RPM_CACHE_DIR}
cp $RPM_FILE ${RPM_CACHE_DIR}
ln ${RPM_CACHE_DIR}/rpm-packages.txt ${OUTPUT_DIR}/temp/rpm/rpm-packages.txt

## PIP

mkdir -p ${PIP_CACHE_DIR}

# Let PIP do the work of downloading and verifying packages
pip download -d ${PIP_CACHE_DIR} -r ${LIST}/pip-requirements.txt

# Link packages and requirements file into VM's temp directory
mkdir -p ${OUTPUT_DIR}/temp/pip
ln ${PIP_CACHE_DIR}/* ${OUTPUT_DIR}/temp/pip/
ln ${LIST}/pip-requirements.txt ${OUTPUT_DIR}/temp/requirements.txt

###
### 4. Link the nested VM image
###
rm -fr ${OUTPUT_DIR}/temp/nested-vm
mkdir ${OUTPUT_DIR}/temp/nested-vm
ln $NESTED_IMG ${OUTPUT_DIR}/temp/nested-vm/

###
### 5. Create Version and Changelog files
###

echo ${RELEASE} > ${OUTPUT_DIR}/temp/VERSION
ln CHANGELOG ${OUTPUT_DIR}/temp/CHANGELOG

###
### 6. Run packer
###
export PACKER_LOG=1
export PACKER_LOG_PATH=${OUTPUT_DIR}/packer.log
${PACKER_DIR}/packer build -var "release=${RELEASE}" \
 -only ${RELEASE}-${OUTPUT_PROVIDER} \
 -var "output_dir=${OUTPUT_DIR}/packer" \
 -var "temp_dir=${OUTPUT_DIR}/temp" \
 -var "atlas_version=${ATLAS_VERSION}" \
 -force \
 -machine-readable ${PACKER_TEMPLATE}

# TODO: Need to figure out "packer push" later. Currently keeps failing.
# ${PACKER_DIR}/packer push -name ckoester/test123 -var "release=${RELEASE}" \
#   -var "output_dir=${OUTPUT_DIR}/packer" \
#   -var "temp_dir=${OUTPUT_DIR}/temp" \
#   ${PACKER_TEMPLATE}

###
### 7. Clean up
###
rm -fr ${OUTPUT_DIR}/temp

echo "Done."
echo "Artifacts:"
echo
ls -lR ${OUTPUT_DIR}
