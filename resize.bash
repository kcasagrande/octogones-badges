#!/usr/bin/env bash

usageMessage="Usage: ${0} { -o | --output-directory <OUTPUT_DIRECTORY> }
                          [ -f | --force ]"

usage () {
	echo ${usageMessage} >&2
	exit 1
}

parsedArguments=$(getopt -n ${0} -o o:f --long output-directory:,force -- "${@}")
validArguments=$?
if [ \! ${validArguments} ]; then
	usage
fi
eval set -- "${parsedArguments}"
while :
do
	case "${1}" in
		"-o" | "--output-directory")
			argOutputDirectory="${2}"
			shift 2
			;;
		"-f" | "--force")
			argForce=true
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

nameTextId="text-name"
nameHintId="hint-name"
entityTextId="text-entity"
entityHintId="hint-entity"
outputDirectory=${argOutputDirectory:?${usageMessage}}
force=${argForce:-false}

getInkscapeActions () {
	textId="${1}"
	hintId="${2}"
	file="${3}"

	textWidth=$(inkscape --query-id=${textId} --query-width "${file}")
	hintWidth=$(inkscape --query-id=${hintId} --query-width "${file}")
	horizontalRatio=$(echo "scale=3;${hintWidth}/${textWidth}" | bc)
	textHeight=$(inkscape --query-id=${textId} --query-height "${file}")
	hintHeight=$(inkscape --query-id=${hintId} --query-height "${file}")
	verticalRatio=$(echo "scale=3;${hintHeight}/${textHeight}" | bc)
	if [ $(echo "${horizontalRatio} < ${verticalRatio}" | bc) -ne 0 ] ; then
		ratio=${horizontalRatio}
	else
		ratio=${verticalRatio}
	fi
	if [ $(echo "${ratio} < 1" | bc) -ne 0 ] ; then
		delta=$(echo "scale=3;(${ratio} * ${textWidth}) - ${textWidth}" | bc)
		echo "select-by-id:${textId};transform-scale:${delta};select-by-id:${hintId};object-align:hcenter vcenter last;select-clear;"
	else
		echo "select-by-id:${textId};select-by-id:${hintId};object-align:hcenter vcenter last;select-clear;"
	fi
}

${force} && [ -d "${outputDirectory}" ] && rm -Rf "${outputDirectory}"
mkdir -p "${outputDirectory}"
for sourceFile in $* ; do
	targetFile="${outputDirectory}/$(basename "${sourceFile}" .svg).png"
	nameActions=$(getInkscapeActions "${nameTextId}" "${nameHintId}" "${sourceFile}")
	entityActions=$(getInkscapeActions "${entityTextId}" "${entityHintId}" "${sourceFile}")
	actions="${nameActions:-}${entityActions:-}export-dpi:300;export-filename:${targetFile};export-do;file-close" 
	inkscape --actions="${actions}" "${sourceFile}" 2>/dev/null
done
