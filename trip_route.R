## OSRM Process Routes
#library(iotools)
library(osrm)

args = commandArgs(trailingOnly=TRUE)
if (length(args)<2) {
  stop("need an input file and port", call.=FALSE)
}

input_file <- args[1]
port <- args[2]
options(osrm.server = paste0("http://localhost:", port, "/"), osrm.profile = "car")

chunksize = 5000
all_trips <- read.csv(input_file)
print(paste0("Got ", nrow(all_trips), " trips to process in chunks of ", chunksize, " (max)"))

all_trips$duration <- 0.0
all_trips$distance <- 0.0
results <- all_trips[0,]

query_osrm <- function (row) {
    return(
        tryCatch(
            osrmRoute(
                src = c(row["src_lon"], row["src_lat"]),
                dst = c(row["dst_lon"], row["dst_lat"]),
                overview = FALSE),
            error=function(e) NULL
        )
    )
}

chunks = ceiling(nrow(all_trips) / chunksize)
for (C in 1:chunks) {
    print(paste0(format(Sys.time(), "%F :: %H:%M:%S"), " :: working on ", chunksize, "-row chunk (max) ", C, " of ", chunks))
    cend = C*chunksize
    cstart = cend - chunksize + 1
    if (cend > nrow(all_trips)) {
        cend = nrow(all_trips)
    }
    chunk <- all_trips[cstart:cend,]
    chunk[,6:7] <- apply(chunk, 1, query_osrm)
    results <- rbind(results, chunk)
}

write.csv(results, paste0("output/output-", strsplit(input_file, "/")[[1]][2]), row.names=FALSE)
