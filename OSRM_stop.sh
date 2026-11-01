#!/bin/bash

LOCATION=${1:?example 'bangladesh'}
PORT=${2:?example '5000'}

## SHUT DOWN SERVER
apptainer -v instance stop OSRM-$LOCATION-$PORT
echo "$(date) :: all done!"
