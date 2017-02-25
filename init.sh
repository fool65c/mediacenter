#! /bin/sh

###config###
GIT_ROOT="https://github.com/kevinmager65"
DOCKER_SERVICES=(docker-sabnzbd docker-sickbeard docker-couchpotato docker-plex docker-bind docker-proxy)

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

if [ ! -d ".build" ]; then
	echo "creating .build directory"
	mkdir .build
fi

for service in ${DOCKER_SERVICES[@]}; do
	echo "deploying: $service"
	
	if [ -d ".build/${service}" ]; then
		echo "${service} exists... updating"
		cd .build/${service}
		git pull
	else
		git_location="${GIT_ROOT}/${service}.git"
		echo "git location: ${git_location}"
		git clone $git_location .build/${service}
		cd .build/$service
	fi

	docker-compose build
	docker-compose stop
	docker-compose up -d

	cd ../..
done





