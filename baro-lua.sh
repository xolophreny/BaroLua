#!/bin/bash

update() {
	echo "Updating..."
	wget -O baro.tar.gz https://github.com/evilfactory/LuaCsForBarotrauma/releases/download/latest/luacsforbarotrauma_build_linux.tar.gz
	tar xf baro.tar.gz
	echo "Copying Content, Data..."
	for item in Content Data; do
		cp -r ${BARO_DIR}/${item} ./
	done
	echo "LocalMods, ModLists, config_player.xml, serversettings.xml..."
	if [[ ${LINKING} -ne 0 ]] ; then
		# Link configs and local mods for consistency between Vanilla and Lua
		for item in LocalMods ModLists config_player.xml serversettings.xml; do
			if [[ ! -L ${item} ]] ; then 
				rm -r ${item}
				ln -s ${BARO_DIR}/${item} ./
			fi
		done
	else
		# Or just copy them
		for item in LocalMods ModLists config_player.xml serversettings.xml; do
			if [[ -L ${item} ]] ; then
				rm ${item}
			fi
			cp -r ${BARO_DIR}/${item} ./
		done
	fi
	cleanup
	echo "Finished updating."
}

run() {
	echo "Running..."
	if [[ ${VARS} -ne 0 ]] ; then # Additional variables from -e
		export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
		export DRI_PRIME=1
		export MESA_GLTHREAD=1
	fi
	exec ./Barotrauma
}

cleanup() {
	echo "Cleanup..."
	[[ -e baro.tar.gz ]] && rm baro.tar.gz
}

usage() {
	echo "Usage:	$(basename $0) {-u|-r} [-d <dir>] [-l <dir>]"
	echo "Options:"
	echo "	-u		Update to the latest Lua release"
	echo "	-r		Run Barotrauma Lua"
	echo
	echo "	-d		Set vanilla Barotrauma directory. Default:"
	echo "			~/.local/share/Steam/steamapps/common/Barotrauma"
	echo
	echo "	-l		Set LuaForBarotrauma directory. Default:"
	echo "			~/.local/share/barotrauma-lua"
	echo
	echo "	-e		Set additional env variables for running Barotrauma"
	echo "			User-specific, please change the script accordingly"
	echo
	echo "	-s		Make symbolic links to vanilla configs instead of copying"
	echo "			Useful for consistency between Vanilla and Lua"
}


BARO_DIR=~/.local/share/Steam/steamapps/common/Barotrauma
LUA_DIR=~/.local/share/barotrauma-lua
UPDATE=0
RUN=0
VARS=0
LINKING=0

# Processing parameters
while [[ ${1:0:1} = '-' ]] ; do # While the first parameter starts with a dash
	N=1 # Character counter
	while [[ $N -lt ${#1} ]] ; do # Going through every character in a parameter
		case ${1:$N:1} in # Case of Nth character
			'u') 
				UPDATE=1;;
			'r')
				RUN=1;;
			'd')
				# If not last character in a blob, or if no subsequent parameter
				if [[ $N -ne $((${#1}-1)) || ! -n ${2} ]] ; then
					usage
					exit 1
				fi
				BARO_DIR=${2}
				shift;; # Shift through the subsequent parameter
			'l')
				if [[ $N -ne $((${#1}-1)) || ! -n ${2} ]] ; then
					usage
					exit 1
				fi
				LUA_DIR=${2}
				shift;;
			'e')
				VARS=1;;
			's')
				LINKING=1;;
			*)
				usage
				exit 1;;
		esac
		N=$(($N+1))
	done
	shift
done

# Doing things
if which wget &> /dev/null && which tar &> /dev/null; then

	if [[ ${UPDATE} -eq 0 && ${RUN} -eq 0 ]] ; then
		usage
		exit 1
	fi
	
	if [[ ! -x ${BARO_DIR}/Barotrauma ]] ; then
		echo "Regular Barotrauma not found."
		echo "(${BARO_DIR}/Barotrauma does not exist or is not executable)"
		usage
		exit 1
	fi
	
	echo "Barotrauma dir is ${BARO_DIR}"
	echo "It will be used to copy contents and user settings to Lua dir."
	echo "Lua dir is ${LUA_DIR}"
	trap cleanup SIGINT
	mkdir -p ${LUA_DIR}
	cd ${LUA_DIR}
	if [[ $UPDATE -ne 0 ]] ; then update; fi
	if [[ $RUN -ne 0 ]] ; then run; fi
else
	echo "Requires wget and tar."
	exit 1
fi
