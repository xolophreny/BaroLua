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
	if [ ${linking} -ne 0 ] ; then
		# Link configs and local mods for consistency between Vanilla and Lua
		for item in LocalMods ModLists config_player.xml serversettings.xml; do
			if [ ! -L ${item} ] ; then 
				rm -r ${item}
				ln -s ${baro_dir}/${item} ./
			fi
		done
	else
		# Or just copy them
		for item in LocalMods ModLists config_player.xml serversettings.xml; do
			if [ -L ${item} ] ; then
				rm ${item}
			fi
			cp -r ${baro_dir}/${item} ./
		done
	fi
	cleanup
	echo "Finished updating."
}

run() {
	if [ "$vars" != "" ] ; then
		echo "Variables: $vars"
	fi
	if [ ! -x ./Barotrauma ] ; then
		echo "Make sure to install Barotrauma Lua with -u first."
		exit 1
	fi
	echo "Running..."
	exec env $vars ./Barotrauma
}

cleanup() {
	echo "Cleanup..."
	[ -e baro.tar.gz ] && rm baro.tar.gz
}

usage() {
	echo "Usage:	$(basename $0) {-u|-r} [-s] [-d <dir>] [-l <dir>] [-e <envvar>]"
	echo "Options:"
	echo "	-u		Update to the latest Lua release."
	echo "	-r		Run Barotrauma Lua."
	echo
	echo "	-d		Set vanilla Barotrauma directory. Default:"
	echo "			~/.local/share/Steam/steamapps/common/Barotrauma"
	echo
	echo "	-l		Set LuaForBarotrauma directory. Default:"
	echo "			~/.local/share/barotrauma-lua"
	echo
	echo "	-e		Set additional env variables for running Barotrauma. Example:"
	echo "			-e DRI_PRIME=1 -e MESA_GLTHREAD=1"
	echo
	echo "	-s		Make symbolic links to vanilla configs instead of copying."
	echo "			Useful for consistency between Vanilla and Lua."
}


baro_dir=~/.local/share/Steam/steamapps/common/Barotrauma
lua_dir=~/.local/share/barotrauma-lua
update=0
run=0
vars=""
linking=0

# Processing parameters
while [ "${1:0:1}" = '-' ] ; do # While the first parameter starts with a dash
	n=1 # Character counter
	l=${#1} # Length of parameter
	while [ $n -lt $l ] ; do # Going through every character in a parameter
		case ${1:$n:1} in # Case of Nth character
			'u') 
				update=1;;
			'r')
				run=1;;
			's')
				linking=1;;
			'd')
				# If not last character in a blob, or if no subsequent parameter
				if [ $n -ne $(($l-1)) -o ! -n ${2} ] ; then
					usage
					exit 1
				fi
				baro_dir=${2}
				shift;; # Shift through the subsequent parameter
			'l')
				if [ $n -ne $(($l-1)) -o ! -n ${2} ] ; then
					usage
					exit 1
				fi
				lua_dir=${2}
				shift;;
			'e')
				if [ $n -ne $(($l-1)) -o ! -n ${2} ] ; then
					usage
					exit 1
				fi
				vars+="${2} "
				shift;;
			*)
				usage
				exit 1;;
		esac
		n=$(($n+1))
	done
	shift
done

# Doing things
if which wget &> /dev/null && which tar &> /dev/null && which env &> /dev/null; then
	if [ ${update} -eq 0 -a ${run} -eq 0 ] ; then
		usage
		exit 1
	fi
	
	if [ ! -x "${baro_dir}/Barotrauma" ] ; then
		echo "Regular Barotrauma not found."
		echo "(${baro_dir}/Barotrauma does not exist or is not executable)"
		exit 1
	fi
	
	echo "Barotrauma dir is ${baro_dir}"
	echo "It will be used to copy contents and user settings to Lua dir."
	echo "Lua dir is ${lua_dir}"
	mkdir -p ${lua_dir}
	if [ ! -e "${lua_dir}" ] ; then
		echo "Could not find or create ${lua_dir}"
		exit 1
	fi
	cd ${lua_dir}
	trap cleanup SIGINT
	if [ $update -ne 0 ] ; then update; fi
	if [ $run -ne 0 ] ; then run; fi
else
	echo "Requires env, wget and tar."
	exit 1
fi
