#!/bin/bash

set -eo pipefail

## FUNCTIONS

setup_dirs () {
    echo -n "$(date) :: $1 check or create ... "
    if [[ ! -d $1 ]]; then
        echo -n "creating ... "
        mkdir -p $1
        echo "created"
    else
        echo "exists"
    fi
}

setup_pbf () {
    # $PBF_FILE_URL $DATA_DIR_BASE $PROFILE
    echo -n "$(date) :: check or get $1 ... "
    if [[ ! -f $2/pbf_files/$PBF_FILE ]]; then
        echo -n "getting ... "
        wget -O $2/pbf_files/$PBF_FILE $1
        echo "downloaded"
    else
        echo "exists"
    fi
    if [[ ! -e $2/$3/$PBF_FILE ]]; then
        # need the PBF, but a link is fine
        ln $2/pbf_files/$PBF_FILE $2/$3/$PBF_FILE
    fi
}

setup_OSRM_sif () {
    echo -n "$(date) :: check or create OSRM container ... "
    if [[ ! -f OSRM.sif ]]; then
        echo -n "building ... "
        apptainer build OSRM.sif docker:osrm/osrm-backend
        echo "built"
    else
        echo "exists"
    fi
}

setup_OSRM_profile () {
#    $PBF_FILE $DATA_DIR_BASE $PROFILE
    echo -e "$(date) :: check or create OSRM Profile Dataset:\n  #####\n  PBF File: $1 \n  Profile: $3 \n  DataDir: $2 \n  #####"
    OSRM_FILE="$(basename -s.osm.pbf $1).osrm"
    THREADS=$(($(nproc) / 4 * 3))
    if [[ ! -f $2/$3/$OSRM_FILE ]]; then
        echo -e "\n  #################\n  STEP 1 of 3 \n  #################\n"
        apptainer run -B $2/$3:/data OSRM.sif osrm-extract -t $THREADS -p /opt/$3.lua /data/$1
        echo -e "\n  #################\n  STEP 2 of 3 \n  #################\n"
        apptainer run -B $2/$3:/data OSRM.sif osrm-partition -t $THREADS /data/$OSRM_FILE
        echo -e "\n  #################\n  STEP 3 of 3 \n  #################\n"
        apptainer run -B $2/$3:/data OSRM.sif osrm-customize -t $THREADS /data/$OSRM_FILE
        # fix bad perm

        chmod 664 $2/$3/${OSRM_FILE}.fileIndex
    else
        echo "$(date) :: $OSRM_FILE exists, no work"
    fi    
    echo -e "\n  #################\n  ALL DONE \n  #################\n"
}

## MAIN
PBF_FILE_URL=${1:?need a PBF file URL to process (example: https://download.geofabrik.de/asia/bangladesh-latest.osm.pbf)}
PROFILE=${2:?need a PROFILE ('bicycle', 'car', or 'foot')}
DATA_DIR_BASE="$PWD/data"
PBF_FILE="$(basename $PBF_FILE_URL)"
LOCATION="$(basename -s -latest.osrm.pbf $PBF_FILE)"

echo """$(date) :: Starting OSRM Setup with:

  ##############
  LOCATION:       $LOCATION
  PBF_FILE_URL:   $PBF_FILE_URL
  PBF_FILE:       $PBF_FILE
  DATA_DIR_BASE:  $DATA_DIR_BASE
  PROFILE:        $PROFILE
  ##############

"""

echo "$(date) :: Working on LOCATION $LOCATION PROFILE $PROFILE ..."
setup_dirs $DATA_DIR_BASE/pbf_files
setup_dirs $DATA_DIR_BASE/$PROFILE
setup_pbf  $PBF_FILE_URL $DATA_DIR_BASE $PROFILE
setup_OSRM_sif
setup_OSRM_profile $PBF_FILE $DATA_DIR_BASE $PROFILE
echo $(date) :: done with $PBF_FILE with PROFILE $PROFILE
