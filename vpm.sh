#!/bin/bash

# VARS project manager (vpm).
# © Andrew Wei
#
# This software is released under the MIT License:
# http://www.opensource.org/licenses/mit-license.php

{ # This ensures the entire script is downloaded #

# Config.
VPM_VERSION="0.11.0"

# Colors.
COLOR_PREFIX="\x1b["
COLOR_RESET=$COLOR_PREFIX"0m"
COLOR_BLACK=$COLOR_PREFIX"0;30m"
COLOR_RED=$COLOR_PREFIX"0;31m"
COLOR_GREEN=$COLOR_PREFIX"0;32m"
COLOR_ORANGE=$COLOR_PREFIX"0;33m"
COLOR_BLUE=$COLOR_PREFIX"0;34m"
COLOR_PURPLE=$COLOR_PREFIX"0;35m"
COLOR_CYAN=$COLOR_PREFIX"0;36m"
COLOR_LIGHT_GRAY=$COLOR_PREFIX"0;37m"

# Paths.
PATH_VPM_ROOT="${BASH_SOURCE%/*}"
PATH_REPOSITORY=$PATH_VPM_ROOT"/registry"
PATH_CACHE=$PATH_VPM_ROOT"/registry-cache"
PATH_HOSTS="/etc/hosts"
PATH_VHOSTS="/etc/apache2/extra/httpd-vhosts.conf"

# @global
# 
# Checks if a command is available
#
# @param $1 Name of the command.
function VPM_HAS() {
  type "$1" > /dev/null 2>&1
}

# @global
#
# Serializes the registry into an array of project entries in the form of
# "key":"path" string pair. This operation stores the array of project entries
# into VPM_PROJECT_LIST and its length into VPM_PROJECT_LENGTH.
function VPM_SERIALIZE_REPOSITORY() {
	# Reset global variable.
	VPM_PROJECT_LIST=()

	if [ -e $PATH_REPOSITORY ]; then
		# Read line-by-line.
		while read l; do
			if [[ $l == *:* ]]; then
				VPM_PROJECT_LIST=("${VPM_PROJECT_LIST[@]}" "$l")
			else
				continue
			fi
		done <$PATH_REPOSITORY
	fi

	VPM_PROJECT_LENGTH=${#VPM_PROJECT_LIST[@]}
}

# @global
#
# Parses a project entry in the form of "key":"path" string pair and stores
# the key and the path into VPM_TMP_PROJECT_ALIAS and VPM_TMP_PROJECT_PATH
# respectively.
#
# @param $1 The "key":"path" string pair.
function VPM_DECODE_PROJECT_PAIR() {
	if [ "$1" == "" ]; then return; fi

	# Configure IFS to split the pair appropriately while preserving
	# whitespaces.
	OIFS=$IFS
	IFS=":"

	# Grab the key from the "key":"path" string pair.
	local a=($1)
	local n=${a[0]}
	local p=${a[1]}

	# Restore IFS.
	IFS=$OIFS

	# Filter out quotations.
	n=${n//\"/}
	n=${n//\'/}
	p=${p//\"/}
	p=${p//\'/}

	# Store the key and path globally.
	VPM_TMP_PROJECT_ALIAS="$n"
	VPM_TMP_PROJECT_PATH="$p"
}

# @global
#
# Looks up the vpm repo by key, index, or cache and stores the matching
# project pair globally.
#
# @param $1 Project key or index
function VPM_GET_PROJECT_PAIR() {
	if [ "$1" == "" ]; then
		VPM_GET_CACHE
		VPM_GET_PROJECT_PAIR_BY_ALIAS $VPM_PROJECT_CACHE
		return
	fi

	# . means get the project key from cache.
	if [ "$1" == "." ]; then
		VPM_GET_PROJECT_PAIR_BY_PATH "$(pwd)"
		return
	fi

	# Check if getting project pair by key or index.
	[[ $1 =~ ^-?[0-9]+$ ]] && use_idx=1 || use_idx=0

	if (($use_idx == 1)); then
		VPM_GET_PROJECT_PAIR_BY_INDEX $1
	else
		VPM_GET_PROJECT_PAIR_BY_ALIAS $1
	fi
}

# @global
#
# Looks up the vpm repo by key and stores the matching project pair globally.
#
# @param $1 Project key
function VPM_GET_PROJECT_PAIR_BY_ALIAS() {
	if [ "$1" != "" ]; then
		VPM_SERIALIZE_REPOSITORY

		# Iterate through the list of projects.
		for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
			VPM_DECODE_PROJECT_PAIR "${VPM_PROJECT_LIST[$((i - 1))]}"

			if [ "$VPM_TMP_PROJECT_ALIAS" == "$1" ]; then
				return
			fi
		done
	fi

	VPM_TMP_PROJECT_ALIAS=""
	VPM_TMP_PROJECT_PATH=""
}

# @global
#
# Looks up the vpm repo by index and stores the matching project pair globally.
#
# @param $1 Project index
function VPM_GET_PROJECT_PAIR_BY_INDEX() {
	if [ "$1" != "" ]; then
		VPM_SERIALIZE_REPOSITORY

		# Iterate through the list of projects.
		for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
			VPM_DECODE_PROJECT_PAIR "${VPM_PROJECT_LIST[$((i - 1))]}"

			if (($i == $1)); then
				return
			fi
		done
	fi

	VPM_TMP_PROJECT_ALIAS=""
	VPM_TMP_PROJECT_PATH=""
}

# @global
#
# Looks up the vpm repo by path and stores the matching
# project pair globally.
#
# @param $1 Project path
function VPM_GET_PROJECT_PAIR_BY_PATH() {
	if [ "$1" != "" ]; then
		VPM_SERIALIZE_REPOSITORY

		# Iterate through the list of projects.
		for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
			VPM_DECODE_PROJECT_PAIR "${VPM_PROJECT_LIST[$((i - 1))]}"

			if [ "$VPM_TMP_PROJECT_PATH" == "$1" ]; then
				return
			fi
		done
	fi

	VPM_TMP_PROJECT_ALIAS=""
	VPM_TMP_PROJECT_PATH=""
}

# @global
#
# Stores the cached key globally.
function VPM_GET_CACHE() {
	if [ -e $PATH_CACHE ]; then
		VPM_PROJECT_CACHE=$(<$PATH_CACHE)
	else
		VPM_PROJECT_CACHE=""
	fi
}

# @global
#
# Writes the last used project key into cache.
#
# @param $1 Project key to be cached
function VPM_SET_CACHE() {
	if [ "$1" == "" ]; then return; fi

	# Iterate through the list of projects.
	for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
		VPM_DECODE_PROJECT_PAIR "${VPM_PROJECT_LIST[$((i - 1))]}"

		if [ "$VPM_TMP_PROJECT_ALIAS" == "$1" ]; then
			echo -e $1 >$PATH_CACHE
			return
		fi
	done

	echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}Problem writing cache"
}

# @global
#
# Opens the provided path in the preferred editor.
#
# @param $1 Path to open.
function VPM_EDIT() {
	if [ "$1" == "" ]; then return; fi

	if VPM_HAS "code"; then
		code "$1"
	elif VPM_HAS "subl"; then
		subl "$1"
	elif VPM_HAS "atom"; then
		atom "$1"
	elif VPM_HAS "mate"; then
    mate "$1"
  else
    echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}No editors available"
  fi
}

# Shows the current cached project key.
function vpm_cache() {
	VPM_GET_CACHE

	if [ "$VPM_PROJECT_CACHE" == "" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}The cache is empty"
	else
		echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}Current project in cache: ${COLOR_CYAN}$VPM_PROJECT_CACHE${COLOR_RESET}"
	fi
}

# Adds to the vpm the current directory associated with the specified project
# key.
#
# @param [$1] Key of project. Leave blank or use "." to use the name of the
#             current directory.
function vpm_add() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "add"
		return
	fi

	VPM_SERIALIZE_REPOSITORY

	local key="$1"
	local dir="$(pwd)"
	local buffer=""
	local check=0

	if [ "$key" == "" ] || [ "$key" == "." ]; then
		key="${PWD##*/}"
	fi

	# Iterate through the list of projects.
	for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
		local pair=${VPM_PROJECT_LIST[$((i - 1))]}

		VPM_DECODE_PROJECT_PAIR "$pair"

		# If the specified project key already exists...
		if [ "$VPM_TMP_PROJECT_ALIAS" == "$key" ]; then
			check=1
			buffer="$buffer$VPM_TMP_PROJECT_ALIAS:${dir}\n"
			# Else just add the current line to the output buffer.
		else
			buffer="$buffer$pair\n"
		fi
	done

	if [ $check == 0 ]; then
		buffer="$buffer$key:${dir}\n"
		echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Mapped ${COLOR_CYAN}$key ${COLOR_RESET}to ${COLOR_CYAN}${dir}${COLOR_RESET}"
	else
		echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Remapped ${COLOR_CYAN}$key${COLOR_RESET} to ${COLOR_CYAN}${dir}${COLOR_RESET}"
	fi

	echo -e $buffer >$PATH_REPOSITORY

	VPM_SERIALIZE_REPOSITORY
	VPM_SET_CACHE $key
}

# Navigates to the root path of a project in Terminal. Either specify a string
# representing the project key or a number prefixed by '#' representing the
# index.
#
# @param $1 Project key or index
function vpm_cd() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "cd"
		return
	fi

	if [ "$1" == "-r" ]; then
		cd $PATH_VPM_ROOT
		return
	fi

	VPM_GET_PROJECT_PAIR $1

	if [ "$VPM_TMP_PROJECT_ALIAS" != "" ]; then
		VPM_SET_CACHE $VPM_TMP_PROJECT_ALIAS
		cd "$VPM_TMP_PROJECT_PATH"
		return
	fi

	echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}Project with reference ${COLOR_CYAN}$1${COLOR_RESET} not found"
}

# Tidies up the registry file, removing blank lines and fixing bad formatting.
function vpm_clean() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "clean"
		return
	fi

	VPM_SERIALIZE_REPOSITORY

	local count=0
	local buffer=""

	# Iterate through the list of projects.
	for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
		local pair=${VPM_PROJECT_LIST[$((i - 1))]}

		VPM_DECODE_PROJECT_PAIR "$pair"

		# Store entry in buffer if it is valid. If invalid it will not be
		# recorded, thus 'cleaned'.
		if [ "$pair" != "" ] && [ "$VPM_TMP_PROJECT_ALIAS" != "" ] && [ "$VPM_TMP_PROJECT_PATH" != "" ]; then
			buffer="$buffer$pair\n"
		else
			count=$((count + 1))
		fi
	done

	echo -e $buffer >$PATH_REPOSITORY
	echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Reconciled $count project(s)"
}

# Lists all the projects managed by vpm.
function vpm_list() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "list"
		return
	fi

	# Update VPM_PROJECT_LIST array.
	VPM_SERIALIZE_REPOSITORY

	if (($VPM_PROJECT_LENGTH == 0)); then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}There are no projects in the registry."
	else
		echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}Found ${COLOR_PURPLE}$VPM_PROJECT_LENGTH${COLOR_RESET} project(s) in the registry"

		for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
			local pair=${VPM_PROJECT_LIST[$((i - 1))]}

			VPM_DECODE_PROJECT_PAIR "$pair"

			echo -e "    $i. ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET}: $VPM_TMP_PROJECT_PATH"
		done
	fi
}

# Edits the local registry.
function vpm_edit_registry() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "manage"
	else
		VPM_EDIT $PATH_REPOSITORY
	fi
}

# Opens a project in Finder. Either specify a string representing the project
# key or a number representing the index.
#
# @param $1 Project key or index
function vpm_open() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "open"
		return
	fi

	# If arg is blank, open root directory of vpm.
	if [ "$1" == "-r" ]; then
		open $PATH_VPM_ROOT
		echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Opened root in Finder"
		return
	fi

	VPM_GET_PROJECT_PAIR $1

	if [[ $VPM_TMP_PROJECT_ALIAS != "" ]]; then
		VPM_SET_CACHE $VPM_TMP_PROJECT_ALIAS
		open "$VPM_TMP_PROJECT_PATH"
		echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Opened project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} in Finder"
	else
		echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}Project with reference ${COLOR_CYAN}$1${COLOR_RESET} not found"
	fi
}

# Removes a project from vpm. Either specify a string representing the project
# key or a number representing the index.
#
# @param $1 Project key or index. Leave blank or specify "." to use the name
#           of the current directory.
function vpm_remove() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "remove"
		return
	fi

	local key="$1"

	if [ "$key" == "" ] || [ "$key" == "." ]; then
		key="${PWD##*/}"
	fi

	[[ $key =~ ^-?[0-9]+$ ]] && use_idx=1 || use_idx=0

	VPM_SERIALIZE_REPOSITORY

	local removed=0
	local buffer=""

	# Iterate through the list of projects.
	for ((i = 1; i <= $VPM_PROJECT_LENGTH; i++)); do
		local pair=${VPM_PROJECT_LIST[$((i - 1))]}
		local skip=0

		VPM_DECODE_PROJECT_PAIR "$pair"

		# If arg is a project index...
		if (($use_idx == 1)) && (($i == $key)); then
			skip=1
			removed=1

			echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Removed project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} at index ${COLOR_PURPLE}$i${COLOR_RESET}"

			# Else if arg is a project key...
		elif (($use_idx == 0)) && [ "$VPM_TMP_PROJECT_ALIAS" == "$key" ]; then
			skip=1
			removed=1

			echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Removed project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} at index ${COLOR_PURPLE}$i${COLOR_RESET}"
		fi

		# If there was no match for this loop...
		if (($skip == 0)); then
			buffer="$buffer$pair\n"
		fi
	done

	# If nothing was removed, throw error.
	if (($removed == 0)); then
		if (($use_idx == 1)); then
			echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}Index ${COLOR_PURPLE}$key${COLOR_RESET} is out of bounds"
		else
			echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}Project with key ${COLOR_CYAN}$key${COLOR_RESET} not found"
		fi
	fi

	echo -e $buffer >$PATH_REPOSITORY
}

# Opens a project from vpm. Either specify a string representing the project
# key or a number representing the index.
#
# @param $1 Project extension
# @param $2 Project key or index
function vpm_project() {
	# Help.
	if [ "$1" == "-h" ]; then
		vpm_help "project"

		return
	fi

	VPM_GET_PROJECT_PAIR $1

	if [ "$VPM_TMP_PROJECT_ALIAS" != "" ]; then
		TARGET_PROJECT_FILE=""

		for file in "$VPM_TMP_PROJECT_PATH"/*; do
			# If *.xcworkspace file is found, use it immediately.
			if [[ "$file" == *"xcworkspace" ]]; then
				TARGET_PROJECT_FILE="$file"
				break
				# If *.xcodeproj is found, store it temporarily until another
				# project file with higher priority is found.
			elif [[ "$file" == *"xcodeproj" ]]; then
				if [[ "$TARGET_PROJECT_FILE" != *"xcworkspace" ]]; then
					TARGET_PROJECT_FILE="$file"
				fi
				# If *.sublime-project is found, store it temporarily until another
				# project file with higher priority is found.
			elif [[ "$file" == *"sublime-project" ]]; then
				if [[ "$TARGET_PROJECT_FILE" != *"xcworkspace" ]] && [[ "$TARGET_PROJECT_FILE" != *"xcodeproj" ]]; then
					TARGET_PROJECT_FILE="$file"
				fi
			fi
		done

		if [[ "$TARGET_PROJECT_FILE" != "" ]]; then
			VPM_SET_CACHE $VPM_TMP_PROJECT_ALIAS

			if [[ "$TARGET_PROJECT_FILE" == *"xcworkspace" ]]; then
				echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Found Xcode workspace, opening project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Xcode${COLOR_RESET}"
			elif [[ "$TARGET_PROJECT_FILE" == *"xcodeproj" ]]; then
				echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Found Xcode project, opening project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Xcode${COLOR_RESET}"
			elif [[ "$TARGET_PROJECT_FILE" == *"sublime-project" ]]; then
				echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}Found Sublime project, opening project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Sublime${COLOR_RESET}"
			fi

			open "$TARGET_PROJECT_FILE"
		else
			VPM_SET_CACHE $VPM_TMP_PROJECT_ALIAS
			echo -e "${COLOR_BLUE}vpm: ${COLOR_GREEN}OK ${COLOR_RESET}No unique project files found, opening project ${COLOR_CYAN}$VPM_TMP_PROJECT_ALIAS${COLOR_RESET} in preferred editor"
			VPM_EDIT "$VPM_TMP_PROJECT_PATH"
		fi

		return
	fi

	echo -e "${COLOR_BLUE}vpm: ${COLOR_RED}ERR! ${COLOR_RESET}Project with reference ${COLOR_CYAN}$2${COLOR_RESET} not found"
}

# Displays the vpm directory.
function vpm_directory() {
	echo
	echo -e "Usage: ${COLOR_BLUE}vpm ${COLOR_CYAN}<command>${COLOR_RESET}"
	echo
	echo -e "where ${COLOR_CYAN}<command>${COLOR_RESET} is one of:"
	vpm_show_commands
	echo
}

# Displays the vpm help directory.
function vpm_help_directory() {
	echo
	echo -e "Usage: ${COLOR_BLUE}vpm ${COLOR_CYAN}help <command>${COLOR_RESET} or ${COLOR_BLUE}vpm ${COLOR_CYAN}<command> -h${COLOR_RESET} "
	echo
	echo -e "where ${COLOR_CYAN}<command>${COLOR_RESET} is one of:"
	vpm_show_commands
	echo
}

# Echoes available vpm commands.
function vpm_show_commands() {
	echo -e "${COLOR_CYAN}     add${COLOR_RESET} - Maps the current working directory to a project key."
	echo -e "${COLOR_CYAN}      cd${COLOR_RESET} - Changes the current working directory to the working directory of a vpm project."
	echo -e "${COLOR_CYAN}   clean${COLOR_RESET} - Cleans the vpm registry by reconsiling invalid entries."
	echo -e "${COLOR_CYAN}    edit${COLOR_RESET} - Edits the vpm registry file directly in the default text editor ${COLOR_PURPLE}(USE WITH CAUTION)${COLOR_RESET}."
	echo -e "${COLOR_CYAN}    help${COLOR_RESET} - Provides access to additional info regarding specific vpm commands."
	echo -e "${COLOR_CYAN}    list${COLOR_RESET} - Lists all current projects managed by vpm."
	echo -e "${COLOR_CYAN}    open${COLOR_RESET} - Opens the working directory of a vpm project in Finder."
	echo -e "${COLOR_CYAN} project${COLOR_RESET} - Opens a vpm project in designated IDE (supports Xcode/Sublime/Atom in respective priority)."
	echo -e "${COLOR_CYAN}  remove${COLOR_RESET} - Removes a vpm project from the vpm registry."
}

# Displays help documents regarding vpm.
function vpm_help() {
	if [ "$1" == "" ] || [ "$1" == "-h" ]; then
		vpm_help_directory
		return
	fi

	echo

	if [ "$1" == "add" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}add <project_alias>${COLOR_RESET}"
		echo
		echo -e "Maps the current working directory to <project_alias> in vpm. If there already exists a project with the same key, its working directory will be replaced."

	elif [ "$1" == "cd" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}cd <project_alias_or_index>${COLOR_RESET}"
		echo
		echo -e "Changes the current working directory to that of the specified ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET}."

	elif [ "$1" == "clean" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}clean${COLOR_RESET}"
		echo
		echo -e "Scans the current vpm registry and reconsiles invalid project entries."

	elif [ "$1" == "edit" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}edit${COLOR_RESET}"
		echo
		echo -e "Edits the vpm registry file directly in the default text editor ${COLOR_PURPLE}(USE WITH CAUTION)${COLOR_RESET}."

	elif [ "$1" == "list" ] || [ "$1" == "ls" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}list${COLOR_RESET}"
		echo
		echo -e "Lists all the current projects managed by vpm."

	elif [ "$1" == "open" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}open <project_alias_or_index>${COLOR_RESET}"
		echo
		echo -e "Opens the working directory of a vpm project specified by ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET} in Finder."

	elif [ "$1" == "project" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}project <project_alias_or_index>${COLOR_RESET}"
		echo
		echo -e "Opens a vpm project specified by ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET} in its designated IDE. vpm scans for the following project files in order: Xcode, and Sublime. If no project files associated with the aforementioned applications are found, this command will be ignored."

	elif [ "$1" == "remove" ] || [ "$1" == "rm" ]; then
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_BLUE}vpm ${COLOR_CYAN}remove <project_alias_or_index>${COLOR_RESET}"
		echo
		echo -e "Removes a project specified by ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET} from the vpm registry."

	else
		echo -e "${COLOR_BLUE}vpm: ${COLOR_PURPLE}HELP ${COLOR_RESET}No help data available regarding ${COLOR_RED}$1${COLOR_RESET} at this point"
	fi

	echo
}

# Main process.
function main() {
  if   [ "$1" == "" ] || [ "$1" == "dir" ] || [ "$1" == "d" ];         then vpm_directory $2
  elif [ "$1" == "add" ] || [ "$1" == "a" ];                           then vpm_add $2
  elif [ "$1" == "cache" ];                                            then vpm_cache $2
  elif [ "$1" == "cd" ];                                               then vpm_cd $2
  elif [ "$1" == "clean" ] || [ "$1" == "c" ];                         then vpm_clean $2
  elif [ "$1" == "help" ] || [ "$1" == "h" ];                          then vpm_help $2
  elif [ "$1" == "list" ] || [ "$1" == "ls" ] || [ "$1" == "l" ];      then vpm_list $2
  elif [ "$1" == "edit" ] || [ "$1" == "e" ];                          then vpm_edit_registry $2
  elif [ "$1" == "open" ] || [ "$1" == "o" ];                          then vpm_open $2
  elif [ "$1" == "remove" ] || [ "$1" == "rm" ] || [ "$1" == "r" ];    then vpm_remove $2
  elif [ "$1" == "project" ] || [ "$1" == "proj" ] || [ "$1" == "p" ]; then vpm_project $2
  elif [ "$1" == "-v" ];                                               then echo -e "v$VPM_VERSION"
  else echo -e "${COLOR_BLUE}vpm: ${COLOR_RESET}Unsupported command:" $1
  fi
}

main

} # This ensures the entire script is downloaded #