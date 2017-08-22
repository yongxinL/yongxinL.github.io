#!/bin/sh
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
# - ver: 1.0
#
# - A utility script to create linked clones of a base virtual machine.
#
#   To run this script, you must first have created (and presumably installed an OS on)
#   a base virtual machine. A single snapshot of the machine must be taken prior to
#   run the script
#
#   After creating and snaphotting the base image, it must be left alone.
#
#	Run esxi-clone.sh with the first argument being the folder name of base image
#	and the second argument being the name of the folder you want the clone output to.
#   
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Shell Opts ----------------------------------------------------------------
set -e

## Vars ----------------------------------------------------------------------
# declare version
script_version="1.0"

## Functions -----------------------------------------------------------------
show_usage() {
	echo ""
	echo "Usage: $0 <master image directory> <clone image directory>"
	echo "- A utility script to create linked clones of a base virtual machine."
	echo ""
	echo "  To run this script, you must first have created (and presumably installed an OS on)"
	echo "  a master virtual machine. A single snapshot of the machine must be taken prior to"
	echo "  run the script"
	echo ""
	echo "  After creating and snaphotting the base image, it must be left alone."
	echo ""
	echo "  Run $0 with the first argument being the folder name of base image"
	echo "  and the second argument being the name of the folder you want the clone output to."
	echo ""
}

clone_vm() {

	# check if the snapshot exist
	local snapfileID=$(grep -E "(scsi|sata)0\:0\.fileName" "${sourcePath}"/*.vmx | grep -o "[0-9]\{6,6\}" | tail -1)
	if [[ $? -ne 0 ]]; then
		echo ""
		echo "ERROR - the required snapshot information is unable find in master vmx file"
		exit 1
	fi

	# create folder for new vm image
	if [ ! -d "${outputPath}" ]; then
		echo "* Creating new directory..."
		mkdir -p "${outputPath}"
	else
		echo "* Removing contents in the folder..."
		ls -1h  "${outputPath}"/*
		rm -f  "${outputPath}"/*
	fi

	# copy required files.
	echo "* Cloning required snapshot and configuration files."

	cp "${sourcePath}"/*-${snapfileID}* "${outputPath}/"
	cp "${sourcePath}"/*.vmx "${outputPath}/${outputName}.vmx"
}

prepare_vm() {

	local escapedPath=$(echo "${sourcePath}" | sed -e 's/[\/&]/\\&/g' | sed 's/ /\\ /g')
	local snapfileID=$(grep -E "(scsi|sata)0\:0\.fileName" "${sourcePath}"/*.vmx | grep -o "[0-9]\{6,6\}" | tail -1)

	# jump into output folder
	cd "${outputPath}"/
	echo "* Delete swap file line, it will be recreated."
	sed -i '/sched.swap.derivedName/d' ./*.vmx
	echo "* Change Display name to ${outputName}"
	sed -i -e '/^displayName =/ s/= .*"/= "'"${outputName}"'\"/' ./*.vmx
	echo "* Change Parent disk path."
	sed -i -e '/parentFileNameHint=/ s/="/="'"${escapedPath}"'/' ./*-"${snapfileID}".vmdk

	echo "* Forcing change of MAC addresses for up to two NICs"
    sed -i '/ethernet0.generatedAddress/d' ./*.vmx
    sed -i '/ethernet0.addressType/d' ./*.vmx
    sed -i '/ethernet1.generatedAddress/d' ./*.vmx
    sed -i '/ethernet1.addressType/d' ./*.vmx

    echo "* Forcing createion of a fresh UUID."
    sed -i '/uuid.location/d' ./*.vmx
    sed -i '/uuid.bios/d' ./*.vmx

    echo "* Updating nvram."
    sed -i -e '/^nvram =/ s/= .*"/= "'"${outputName}.nvram"'\"/' ./*.vmx

    echo "* Creating new machine ID."
    sed -i '/machine.id/d' ./*.vmx
    sed -i -e "\$amachine.id=${outputName}" ./*.vmx
}

register_VM() {

	local escapedPath=$(echo "${outputPath}/${outputName}.vmx" | sed -e 's/[\/&]/\\&/g' | sed 's/ /\\ /g')

	vmID=$(/bin/vim-cmd vmsvc/getallvms | egrep "${outputName}" | awk '{print $1}')
	if [ ! -z "${vmID}" ]; then
		echo "VM ${outputName} already registered, checking with pool!"
	else
		echo "* Registering ${outputName}..."
		vmID=$(/bin/vim-cmd solo/registervm "${outputPath}/${outputName}.vmx" "${outputName}")
	fi
}

## Main ----------------------------------------------------------------------
# prasing argument
if [ $# -le 1 ] || [ $# -gt 2 ]; then
	echo "ERROR - Insufficient arguments! "
	show_usage
	exit 1
fi
# remove trailing / of path if it has one
readonly inFolder=${1%/}
readonly outFolder=${2%/}

# check input folder and make sure the folder end with -master
echo "${inFolder}" | grep -q "\-master$"
if [[ $? -ne 0 ]]; then
	echo ""
	echo "ERROR - input folder MUST end with -master! "
	echo "You entered: ${inFolder}"
	show_usage
	exit 1
fi

sourcePath=$(readlink -f "${inFolder}")
outputName=$(basename "${outFolder}")

if [ "$(dirname "${outFolder}")" == "." ]; then
	parentPath=$(dirname "${sourcePath}")
else
	parentPath=$(dirname "${outFolder}")
fi

# check if the parentPath exist
if [ ! -d "${parentPath}" ]; then
	echo ""
	echo "ERROR - the parent directory of new VM does not exist!"
	exit 1
else
	outputPath="${parentPath}/${outputName}"
fi

## Main process Begins here ------------------------
echo "============================================================"

# cloning VM files
clone_vm

# processing .vmx file
prepare_vm

# register the machine so that it appears in vSphere
register_VM

# Power on the machine if required
#vim-cmd vmsvc/power.on ${vmID}

echo "======================= Done ================================"
