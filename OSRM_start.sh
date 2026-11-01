#!/bin/bash

OSRM_DATA_BASE="$(pwd)/data"
LOCATION=${1:?example 'bangladesh'}
PROFILE=${2:?need an OSRM profile (foot, bicycle, car)}
# MAX_TABLE_SIZE default will support a 1000 x 1000 OSRM Table query:
MAX_TABLE_SIZE=${3:-1000000}

## SET UP THE DATA
OSRM_DATA_FILE="$PROFILE/${LOCATION}-latest.osrm"

# test for data
if [[ ! -f $OSRM_DATA_BASE/$OSRM_DATA_FILE ]]; then
    echo "$OSRM_DATA_BASE/$OSRM_DATA_FILE :: missing, investigate"
    exit 1
else
    echo "$OSRM_DATA_BASE/$OSRM_DATA_FILE :: exists! Starting job"
fi

THREADS=$(($(nproc) * 3 / 4))
OUTDIR="output"
if [[ ! -d $OUTDIR ]]; then
    mkdir $OUTDIR
fi

# get a free port
let PORT=5000
MAX_PORT=$((PORT + 200))
while $(nc -z localhost $PORT); do
    if [[ $PORT -ge $MAX_PORT ]]; then
        echo "can't get a port"
        exit 1
    fi
    let PORT++
done

echo """
Running Job with:
  LOCATION:       $LOCATION
  PROFILE:        $PROFILE
  MAX_TABLE_SIZE: $MAX_TABLE_SIZE
  THREADS:        $THREADS
  PORT:           $PORT
"""

## RUN THE SERVICE
apptainer -v instance run \
    -B "$OSRM_DATA_BASE:/data" \
    OSRM.sif OSRM-$LOCATION-$PORT \
    osrm-routed \
    --port $PORT \
    --threads $THREADS \
    --algorithm mld \
    --max-table-size $MAX_TABLE_SIZE \
    /data/$OSRM_DATA_FILE
if [[ $? -ne 0 ]]; then
    echo "$(date) :: something broke before or during apptainer server start, exiting"
    exit 1
fi

## wait for service to start
MAX_SECONDS=180
let CUR_SECONDS=0
echo -n "$(date) :: waiting for server "
while ! $(nc -z localhost $PORT); do
    if [[ $CUR_SECONDS -ge $MAX_SECONDS ]]; then
        echo "$(date) :: OSRM server out of time ($MAX_SECONDS)!"
        exit 1
    fi
    sleep 1
    echo -n "."
    let CUR_SECONDS++
done
echo
echo "$(date) :: OSRM server is up!"

### THE DATA (EXAMPLE)
#echo "$(date) :: starting R script"
#module load R/4.5.2
#module load gcc
#module load gdal
#Rscript --no-save osrm_example_table.R $LOCATION $PROFILE $POINTS_FILE $PORT
#
### SHUT DOWN SERVER
#apptainer -v instance stop OSRM-$LOCATION-$PORT
#echo "$(date) :: all done!"
