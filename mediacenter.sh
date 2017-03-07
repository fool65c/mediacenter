#! /bin/sh

###config###
GIT_ROOT="https://github.com/kevinmager65"
DOCKER_SERVICES=(docker-sabnzbd docker-sickbeard docker-couchpotato docker-plex docker-bind docker-proxy)
SERVICE_ACTIONS=(stop start restart)

###SABNZDB CONFIG###
export SABNZBD_CONFIG_DIR=/var/app/sabnzbd
export SABNZBD_DATA_DIR=/srv/download
###SICKBEARD CONFIG###
export SICKBEARD_CONFIG_DIR=/var/app/sickbeard
export SICKBEARD_DATA_DIR=/srv
###COUCHPOTATO CONFIG###
export COUCHPOTATO_CONFIG_DIR=/var/app/couchpotato/config
export COUCHPOTATO_DATA_DIR=/var/app/couchpotato/data
export COUCHPOTATO_DOWNLOAD_DIR=/srv/download
export COUCHPOTATO_MOVIE_DIR=/srv/media/movies
###PLEX CONFIG###
export PLEX_CONFIG_DIR=/var/app/plex
export PLEX_DATA_DIR=/srv/media
###BIND CONFIG###
export EXTERNAL_IP=192.168.1.150
###PROXY###
export PROXY_CONFIG_DIR=/var/app/proxy/

###LOCAL BUILD DIR###
BUILD_DIR=./.build

### An extreamly helpful description of what this script does ###
usage () {
	echo "This script will perform actions on docker services"
	echo "\tUsage:"
	echo "\tPerform an action on all known services"
	echo "\t\tmediacenter <action> -bp"
	echo "\t\t\taction: ${SERVICE_ACTIONS[@]}"

	echo "\tPerform an action on one service"
	echo "\t\tmediacenter <service> <action> -bp"
	echo "\t\t\tservice: ${DOCKER_SERVICES[@]}"
	echo "\t\t\ttaction: ${SERVICE_ACTIONS[@]}"

	echo "options"
	echo "\t -b: rebuild the container"
	echo "\t -p: pull the container from source will rebuild the conteiner"
}

### containsElement ###
#Takes a string and an array
# returns 1 if the string is in the array
# returns 0 if the string is not in the array
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 1; done
  return 0
}

### checkBuildDir ###
# Creates the ${BUILD_DIR} if required
checkBuildDir () {
	if [ ! -d "${BUILD_DIR}" ]; then
		echo "creating ${BUILD_DIR} directory"
		mkdir ${BUILD_DIR}
	fi
}

### updateService ###
# @param service: service to be checkout / updated
# @param pull: flag to pull the service if it already exists
# checks out the service from ${git_location}
# puts in into ${BUILD_DIR}/${service}
updateService () {
	service=$1
	pull=$2

	pushd $BUILD_DIR
	if [ -d "${service}" ]; then
		if [ "${pull}" == "1" ]; then
			echo "updating ${service}"
			pushd $service
			if git pull; then
				echo "update complete"
			else
				echo "ERROR UPDATING SERVICE"
				exit 1
			fi
		else
			echo "$service already exists run with -p to update"
		fi
	else
		#clone from source
		git_location="${GIT_ROOT}/${service}.git"
		echo "git location: ${git_location}"
		git clone $git_location ${service}
		popd
	fi
}

### buildService ###
# @param service: the service to be build
# @param build: flag to build or not
buildService () {
	service=$1
	build=$2
	pushd ${BUILD_DIR}
	#Check to see if the service exists
	if [ "${build}" == "0" ]; then
		echo "${service} will not be built"
	else
		#build the service
		pushd ${service}
		docker-compose build
		popd
	fi
	popd
}

### performAction ###
performAction () {
	service=$1
	
	pushd ${BUILD_DIR}
	#turn restart action into a start and stop
	actions=()
	if [ "$2" == "restart" ]; then
		actions=(stop start)
	else
		actions=($2)
	fi
	
	pushd ${service}
	for action in "${actions[@]}"; do
		echo "Performing ${action} on ${service}"
		if [ "$action" == "start" ]; then
			docker-compose start -d
		else
			docker-compose stop
		fi
	done

	popd
	popd
}

###Build service script
SERVICE_BUILD=0
SERVICE_PULL=0
SERVICE_LIST=()
SERVICE_ACTION=""

#Check for specfic service and action
containsElement "$1" "${DOCKER_SERVICES[@]}"
if [ $? -eq 1 ]; then
	SERVICE_LIST+=($1)
	shift
	containsElement "$1" "${SERVICE_ACTIONS[@]}"
	if [ $? -eq 1 ]; then
		SERVICE_ACTION=$1
		shift
	else
		echo "ERROR: unknown action: $1"
		usage
		exit 1
	fi 
else
	#specific action on all services
	containsElement "$1" "${SERVICE_ACTIONS[@]}"
	if [ $? -eq 1 ]; then
		SERVICE_LIST=("${DOCKER_SERVICES[@]}")
		SERVICE_ACTION=$1
		shift
	else
		echo "ERROR: unknown service or action: $1"
		usage
		exit 1
	fi	
fi

while getopts ":bp" opt; do
  case $opt in
    b)
      echo "services will be rebuilt" >&2
      SERVICE_BUILD=1
      ;;
    p)
      echo "services will be pulled from source" >&2
      SERVICE_PULL=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

checkBuildDir

for service in ${SERVICE_LIST[@]}; do
	echo "Performing ${SERVICE_ACTION} on ${SERVICE_LIST[@]}"
	updateService $service $SERVICE_PULL
	buildService $service $SERVICE_BUILD
	performAction $service $SERVICE_ACTION
done