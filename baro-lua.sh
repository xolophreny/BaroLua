#!/bin/bash

update() {
	echo "Updating..."
	wget -O baro.tar.gz https://github.com/evilfactory/LuaCsForBarotrauma/releases/download/latest/luacsforbarotrauma_build_linux.tar.gz
	tar xf baro.tar.gz
	echo "Copying Content, Data..."
	for item in Content Data; do
		cp -r ${baro_dir}/${item} ./
	done
	echo "LocalMods, ModLists, config_player.xml, serversettings.xml..."
	if [[ ${linking} -ne 0 ]] ; then
		# Link configs and local mods for consistency between Vanilla and Lua
		for item in LocalMods ModLists config_player.xml serversettings.xml; do
			if [[ ! -L ${item} ]] ; then 
				rm -r ${item}
				ln -s ${baro_dir}/${item} ./
			fi
		done
	else
		# Or just copy them
		for item in LocalMods ModLists config_player.xml serversettings.xml; do
			if [[ -L ${item} ]] ; then
				rm ${item}
			fi
			cp -r ${baro_dir}/${item} ./
		done
	fi
	cleanup
	echo "Finished updating."
}

run() {
	echo "Running..."
	if [[ ${vars} -ne 0 ]] ; then # Additional variables from -e
		echo "...with variables..."
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


baro_dir=~/.local/share/Steam/steamapps/common/Barotrauma
lua_dir=~/.local/share/barotrauma-lua
update=0
run=0
vars=0
linking=0

# Processing parameters
while [[ ${1:0:1} = '-' ]] ; do # While the first parameter starts with a dash
	n=1 # Character counter
	l=${#1} # Length of parameter
	while [[ $n -lt $l ]] ; do # Going through every character in a parameter
		case ${1:$n:1} in # Case of Nth character
			'u') 
				update=1;;
			'r')
				run=1;;
			'd')
				# If not last character in a blob, or if no subsequent parameter
				if [[ $n -ne $(($l-1)) || ! -n ${2} ]] ; then
					usage
					exit 1
				fi
				baro_dir=${2}
				shift;; # Shift through the subsequent parameter
			'l')
				if [[ $n -ne $(($l-1)) || ! -n ${2} ]] ; then
					usage
					exit 1
				fi
				lua_dir=${2}
				shift;;
			'e')
				vars=1;;
			's')
				linking=1;;
			*)
				usage
				exit 1;;
		esac
		n=$(($n+1))
	done
	shift
done

# Doing things
if which wget &> /dev/null && which tar &> /dev/null; then
	if [[ ${update} -eq 0 && ${run} -eq 0 ]] ; then
		usage
		exit 1
	fi
	
	if [[ ! -x ${baro_dir}/Barotrauma ]] ; then
		echo "Regular Barotrauma not found."
		echo "(${baro_dir}/Barotrauma does not exist or is not executable)"
		exit 1
	fi
	
	echo "Barotrauma dir is ${baro_dir}"
	echo "It will be used to copy contents and user settings to Lua dir."
	echo "Lua dir is ${lua_dir}"
	trap cleanup SIGINT
	mkdir -p ${lua_dir}
	cd ${lua_dir}
	if [[ $update -ne 0 ]] ; then update; fi
	if [[ $run -ne 0 ]] ; then run; fi
else
	echo "Requires wget and tar."
	exit 1
fi
