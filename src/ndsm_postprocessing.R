#! /usr/bin/env Rscript

library(raster)

# Input
input_dir_path <- ""
output_dir_path <- ""
binning <- TRUE
rgb <- FALSE


# Validate input ----
if (!dir.exists(input_dir_path)) {
  stop("Invalid input_dir_path! Input directory does not exist.")
}

if (!dir.exists(output_dir_path)) {
  stop("Invalid output_dir_path! Output directory does not exist.")
}

if (length(list.files(output_dir_path)) != 0) {
  stop("Invalid output_dir_path! Output directory is not empty.")
}

# Postprocess ndsm ----
postprocess_ndsm <- function(ndsm) {
  clamped_ndsm <- raster::clamp(
    ndsm,
    lower = 0.0,
    upper = 30.0)

  if (binning) {
    clamped_ndsm <- floor(clamped_ndsm)
  }

  postprocessed_ndsm <- round(clamped_ndsm * 8.5)
  return(postprocessed_ndsm)
}

ndsm_paths <- list.files(
  input_dir_path,
  pattern = ".tif$",
  full.names = TRUE)

for (ndsm_path in ndsm_paths) {
  ndsm <- raster::raster(ndsm_path)
  postprocessed_ndsm <- postprocess_ndsm(ndsm)

  upsampled_ndsm <- raster::raster(
    ncol = 5000,
    nrow = 5000,
    crs = raster::projection(postprocessed_ndsm),
    ext = raster::extent(postprocessed_ndsm),
    vals = NA)
  upsampled_ndsm <- raster::resample(
    postprocessed_ndsm,
    upsampled_ndsm,
    method = "ngb")

  if (rgb) {
    upsampled_ndsm <- raster::brick(
      upsampled_ndsm,
      upsampled_ndsm,
      upsampled_ndsm)
    colortable(upsampled_ndsm) <- matrix(c(1,0,0, 0,1,0, 0,0,1), ncol = 3)
  }

  raster::writeRaster(
    upsampled_ndsm,
    filename = file.path(output_dir_path, basename(ndsm_path)),
    format = "GTiff",
    datatype = "INT1U")
}
