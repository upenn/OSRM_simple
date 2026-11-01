## OSRM Process MATRIX of ALL Routes via OSRM Table
library(osrm)

args = commandArgs(trailingOnly=TRUE)
if (length(args)<2) {
  stop("need an input file and port", call.=FALSE)
}

input_file <- args[1]
port <- args[2]
options(osrm.server = paste0("http://localhost:", port, "/"), osrm.profile = "car")

all_points <- read.csv(input_file)
print(paste0("Got ", nrow(all_points), " trips to process"))

results <- osrmTable(
    loc = all_points[, c("lon", "lat")],
    measure = c('duration', 'distance')
)

saveRDS(results, paste0("output/output-", strsplit(input_file, "/")[[1]][2], ".rds"))
