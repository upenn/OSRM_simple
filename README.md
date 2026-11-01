## Setup OSRM and Serve and Query Data

### Source
Converted from https://github.com/Project-OSRM/osrm-backend/pkgs/container/osrm-backend

### Prerequisite: GitHub UPenn with SSH Key Authorization

If you don't already have an SSH Key set up for GitHub, and the key associated with your GitHub account, see our [Key Setup](KEY_setup.md) document for detailed instructions.

### Prerequisite: Apptainer Installed

Please see the [Apptainer - Installing Apptainer](https://apptainer.org/docs/admin/main/installation.html) guide for details. You _do not_ need suid for OSRM, you _do_ need `fuse`.

#### Linux Installation

Assuming Ubuntu (including Windows WSL2 Ubuntu), follow [these instructions](https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages).

Instructions for other sets of pre-built Linux packages can be found [here](https://apptainer.org/docs/admin/main/installation.html#install-from-pre-built-packages).

#### MacOS Installation

More soon!

### Clone the Repository

A one-time task,  after which you'll likely *skip to "[do work](#do-work-example)".*.

```
cd some_path
git clone git@github.com:upenn/OSRM_simple.git
cd OSRM_simple
```

### Build the apptainer Image

A one-time task.

```
cd path/to/OSRM_simple
apptainer build OSRM.sif docker:osrm/osrm-backend
```

### Prepare the OSM Data for Serving

A one-time task per geo area + profile to get and process the osm.pbf.

New York (the state) in this example. Details for the URLs at https://download.geofabrik.de/

```
cd path/to/OSRM_simple
./OSRM_setup.sh PBF_FILE_URL PROFILE
# example (new-york, car):
./OSRM_setup.sh https://download.geofabrik.de/north-america/us/new-york-latest.osm.pbf car
```

### Start the OSRM Server

The `OSRM_start.sh` script file makes starting the OSRM server with your location and profile easy.

```
cd path/to/OSRM_simple
./OSRM_start LOCATION PROFILE
# example (new-york, car):
./OSRM_start.sh new-york car
```

### Stop the OSRM Server

Once you're done with the server, stop it:

```
cd path/to/OSRM_simple
# get the name of your server instance:
apptainer instance list
apptainer -v instance stop INSTANCE_NAME
# example (new-york):
apptainer instance stop OSRM-new-york-car-5000
```

### Do Work With R (Example)

Set up and use R with OSRM.

This is some toy work in `R` ... take a look at [this post](https://jacobbradt.com/blog/2022/osrm-aws/) for some R code using the R `osrm` package.

#### Prerequisites - Ubuntu

Including Windows WSL2 Ubuntu ... install some required packages:

```
sudo apt update
sudo apt install libudunits2-dev gdal-bin gdal-data gdal-plugins libgdal-dev
```

#### Setting Up R

If you're using R, you'll want to do this one-time tasks for the R package `osrm`.

```
Rscript --no-save -e 'install.packages("osrm", dependencies=TRUE)'
```

This can take some time! Grab a ☕︎. Once complete, you're all set to use R with OSRM!

### Run the Example(s)

Build a complete trip matrix between all points in the NYC example points data (11 points):

```
Rscript --no-save trip_table.R input/osrm_example_points_nyc.csv 5000
```

Process all trip routes in the NYC example trip data (5 trips):

```
Rscript --no-save trip_route.R input/osrm_example_trip_nyc.csv 5000
```

Results in `output`.
