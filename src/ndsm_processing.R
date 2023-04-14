#! /usr/bin/env Rscript

library(lidR)
library(raster)

# Input
input_dir_path <- ""
output_dir_path <- ""
chunk_size <- 1000


# Validate input ----
if (!dir.exists(input_dir_path)) {
  stop("Invalid input_dir_path! Input directory does not exist.")
}

if (!dir.exists(output_dir_path)) {
  stop("Invalid output_dir_path! Output directory does not exist.")
}

if (length(list.files(output_dir_path)) != 0) {
  stop("Invalid output_dir_path! Output directory is not empty.")
} else {
  dir.create(file.path(output_dir_path, "classified"))
  dir.create(file.path(output_dir_path, "normalized"))
  dir.create(file.path(output_dir_path, "ndsm"))
}

# Create point cloud catalog ----
las_catalog <- lidR::readLAScatalog(input_dir_path)
lidR::opt_select(las_catalog) <- "xyz"
lidR::opt_chunk_size(las_catalog) <- chunk_size
lidR::opt_chunk_buffer(las_catalog) <- chunk_size / 5

# Classify ground points ----
lidR::opt_output_files(las_catalog) <- file.path(
  output_dir_path,
  "classified",
  "classified_{XLEFT}_{YTOP}")
classified_las_catalog <- lidR::classify_ground(
  las_catalog,
  algorithm = lidR::csf(cloth_resolution=1.0, rigidness=2L))
print("Ground points classified.")

# Normalize point clouds ----
lidR::opt_output_files(classified_las_catalog) <- file.path(
  output_dir_path,
  "normalized",
  "normalized_{XLEFT}_{YTOP}")
normalized_las_catalog <- lidR::normalize_height(
  classified_las_catalog,
  algorithm = lidR::tin())
print("Point clouds normalized.")

# Rasterize normalized point clouds ----
lidR::opt_output_files(normalized_las_catalog) <- file.path(
  output_dir_path,
  "ndsm",
  "ndsm_{XLEFT}_{YTOP}")
ndsm <- lidR::rasterize_canopy(
  normalized_las_catalog,
  res = 0.5,
  algorithm = lidR::p2r())
print("Normalized point clouds rasterized.")
