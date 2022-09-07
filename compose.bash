#!/bin/bash

usageMessage="Usage: ${0} { -t | --template <TEMPLATE_FILE> }
                          { -o | --output-directory <OUTPUT_DIRECTORY> }
                          [ -f | --force ]
                          [ -q | --quiet ]"

usage () {
	echo ${usageMessage} >&2
	exit 1
}

parsedArguments=$(getopt -n ${0} -o t:o:fq --long template:,output-directory:,force,quiet -- "${@}")
validArguments=$?
if [ \! ${validArguments} ]; then
	usage
fi
eval set -- "${parsedArguments}"
while :
do
	case "${1}" in
		"-t" | "--template")
			argTemplate="${2}"
			shift 2
			;;
		"-o" | "--output-directory")
			argOutputDirectory="${2}"
			shift 2
			;;
		"-f" | "--force")
			argForce=true
			shift 1
			;;
		"-q" | "--quiet")
			argQuiet=false
			shift 1
			;;
		"--")
			shift 1
			break
		;;
		*)
			echo "${usageMessage}" >&2
			exit 1
		;;
	esac
done

template=${argTemplate:?${usageMessage}}
outputDirectory=${argOutputDirectory:?${usageMessage}}
force=${argForce:-false}
quiet=${argQuiet:-false}

trace () {
	${quiet} || echo -n "${1}..." >&2
	shift 1
	eval $*
	result=$?
	${quiet} || if [ ${result:-1} -eq 0 ]; then echo " OK." >&2 ; else echo " failed\!" >&2 ; fi
}

compose () {
	source="${1}"
	target="${2}"
	trace "Composing to ${target}" mustache "${source}" "${template}" > "${target}"
}

cleanUp () {
	if ${force} && [ -d "${outputDirectory}" ]; then
		rm -Rf "${outputDirectory}"
	fi
	mkdir -p "${outputDirectory}"
}

cleanUp
for file in $* ; do
	source="${file}"
	target="${outputDirectory}/$(basename "${file}" .yaml).svg"
	compose "${source}" "${target}"
done
