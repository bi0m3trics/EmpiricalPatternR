#include <Rcpp.h>
#include <cmath>
#include <vector>
#include <algorithm>

using namespace Rcpp;
using namespace std;

// ==============================================================================
// OPTIMIZED CANOPY COVER CALCULATION
// ==============================================================================
// This replaces the R version which uses nested loops over grid cells
// C++ version is ~10-50x faster depending on tree density

// [[Rcpp::export]]
double calcCanopyCoverCpp(NumericVector x, NumericVector y, 
                         NumericVector crown_radius, 
                         double plot_size = 100.0, 
                         double grid_res = 0.5) {
    
    int n_trees = x.size();
    int n_cells = ceil(plot_size / grid_res);
    
    // Use vector<bool> for memory efficiency (1 bit per cell)
    vector<bool> grid(n_cells * n_cells, false);
    
    // For each tree, mark covered cells
    for(int i = 0; i < n_trees; i++) {
        double radius = crown_radius[i];
        double radius_sq = radius * radius;  // Pre-compute for speed
        
        // Calculate bounding box
        int x_min = max(0, (int)floor((x[i] - radius) / grid_res));
        int x_max = min(n_cells - 1, (int)ceil((x[i] + radius) / grid_res));
        int y_min = max(0, (int)floor((y[i] - radius) / grid_res));
        int y_max = min(n_cells - 1, (int)ceil((y[i] + radius) / grid_res));
        
        // Check cells in bounding box
        for(int xi = x_min; xi <= x_max; xi++) {
            double cell_x = (xi + 0.5) * grid_res;
            double dx = cell_x - x[i];
            double dx_sq = dx * dx;
            
            for(int yi = y_min; yi <= y_max; yi++) {
                double cell_y = (yi + 0.5) * grid_res;
                double dy = cell_y - y[i];
                
                // Fast distance check (squared distance avoids sqrt)
                if(dx_sq + dy * dy <= radius_sq) {
                    grid[yi * n_cells + xi] = true;
                }
            }
        }
    }
    
    // Count covered cells
    int covered = 0;
    for(int i = 0; i < n_cells * n_cells; i++) {
        if(grid[i]) covered++;
    }
    
    // Return proportion
    return (double)covered / (n_cells * n_cells);
}

// ==============================================================================
// OPTIMIZED NEAREST NEIGHBOR DISTANCE CALCULATION
// ==============================================================================
// Fast calculation of distances to nearest neighbors of specific species
// Used for nurse tree effect (PIED distance to nearest JUSO/JUMO)

// [[Rcpp::export]]
NumericVector calcNearestDistanceCpp(NumericVector x1, NumericVector y1,
                                     NumericVector x2, NumericVector y2) {
    int n1 = x1.size();
    int n2 = x2.size();
    NumericVector min_dist(n1);
    
    if(n2 == 0) {
        // No target trees - return large distances
        fill(min_dist.begin(), min_dist.end(), 1000.0);
        return min_dist;
    }
    
    // For each tree in group 1, find nearest in group 2
    for(int i = 0; i < n1; i++) {
        double min_d = 1e10;
        
        for(int j = 0; j < n2; j++) {
            double dx = x1[i] - x2[j];
            double dy = y1[i] - y2[j];
            double d_sq = dx * dx + dy * dy;
            
            if(d_sq < min_d) {
                min_d = d_sq;
            }
        }
        
        min_dist[i] = sqrt(min_d);
    }
    
    return min_dist;
}

// ==============================================================================
// BATCH ALLOMETRIC CALCULATIONS
// ==============================================================================
// Vectorized calculations for all allometric equations
// Much faster than R loops with by = seq_len(nrow())

// Crown radius calculation (vectorized)
// [[Rcpp::export]]
NumericVector calcCrownRadiusCpp(NumericVector dbh, IntegerVector species_idx,
                                NumericMatrix params) {
    // params: matrix with columns [a, b] and rows for each species
    int n = dbh.size();
    NumericVector radius(n);
    
    for(int i = 0; i < n; i++) {
        int sp = species_idx[i] - 1;  // R uses 1-based indexing
        double a = params(sp, 0);
        double b = params(sp, 1);
        radius[i] = max(0.3, a + b * dbh[i]);  // Min 0.3m
    }
    
    return radius;
}

// Height calculation (vectorized)
// [[Rcpp::export]]
NumericVector calcHeightCpp(NumericVector dbh, IntegerVector species_idx,
                           NumericMatrix params) {
    // params: matrix with columns [a, b] for height = 1.3 + a * (1 - exp(-b * dbh))
    int n = dbh.size();
    NumericVector height(n);
    
    for(int i = 0; i < n; i++) {
        int sp = species_idx[i] - 1;
        double a = params(sp, 0);
        double b = params(sp, 1);
        height[i] = 1.3 + a * (1.0 - exp(-b * dbh[i]));
    }
    
    return height;
}

// Crown base height calculation (vectorized)
// [[Rcpp::export]]
NumericVector calcCrownBaseHeightCpp(NumericVector dbh, NumericVector height,
                                    IntegerVector species_idx, NumericMatrix params) {
    // params: matrix with columns [a, b] for crown_ratio = a - b * log(dbh)
    int n = dbh.size();
    NumericVector crown_base(n);
    
    for(int i = 0; i < n; i++) {
        int sp = species_idx[i] - 1;
        double a = params(sp, 0);
        double b = params(sp, 1);
        double dbh_safe = max(5.0, dbh[i]);
        double crown_ratio = max(0.4, min(0.95, a - b * log(dbh_safe)));
        crown_base[i] = max(0.5, height[i] * (1.0 - crown_ratio));
    }
    
    return crown_base;
}

// ==============================================================================
// FAST CROWN OVERLAP CALCULATION
// ==============================================================================
// Calculate total crown overlap area for quality metrics

// [[Rcpp::export]]
double calcCrownOverlapCpp(NumericVector x, NumericVector y, 
                          NumericVector crown_radius) {
    int n = x.size();
    double total_overlap = 0.0;
    
    // Check all pairs of trees
    for(int i = 0; i < n - 1; i++) {
        for(int j = i + 1; j < n; j++) {
            double dx = x[i] - x[j];
            double dy = y[i] - y[j];
            double dist = sqrt(dx * dx + dy * dy);
            double r_sum = crown_radius[i] + crown_radius[j];
            
            // Check if crowns overlap
            if(dist < r_sum) {
                double r1 = crown_radius[i];
                double r2 = crown_radius[j];
                
                // Calculate overlap area using lens formula
                if(dist <= abs(r1 - r2)) {
                    // One circle completely inside the other
                    total_overlap += M_PI * min(r1, r2) * min(r1, r2);
                } else {
                    // Partial overlap - use lens intersection formula
                    double r1_sq = r1 * r1;
                    double r2_sq = r2 * r2;
                    double dist_sq = dist * dist;
                    
                    double angle1 = acos((dist_sq + r1_sq - r2_sq) / (2.0 * dist * r1));
                    double angle2 = acos((dist_sq + r2_sq - r1_sq) / (2.0 * dist * r2));
                    
                    double area1 = r1_sq * angle1;
                    double area2 = r2_sq * angle2;
                    double triangle = 0.5 * sqrt((r1 + r2 + dist) * (r1 + r2 - dist) * 
                                                (r1 - r2 + dist) * (-r1 + r2 + dist));
                    
                    total_overlap += area1 + area2 - triangle;
                }
            }
        }
    }
    
    return total_overlap;
}

// ==============================================================================
// VECTORIZED DBH AND HEIGHT DISTRIBUTION CALCULATIONS
// ==============================================================================

// Fast calculation of weighted sum of squared differences
// [[Rcpp::export]]
double calcDistributionEnergy(NumericVector values, NumericVector targets,
                             NumericVector weights) {
    int n = values.size();
    double energy = 0.0;
    
    for(int i = 0; i < n; i++) {
        double diff = values[i] - targets[i];
        energy += weights[i] * diff * diff;
    }
    
    return energy;
}

// ==============================================================================
// SPATIAL INDEXING FOR LARGE AREAS
// ==============================================================================
// Grid-based spatial index for fast nearest neighbor queries
// Useful for plots > 1 ha

class SpatialGrid {
public:
    double cell_size;
    int n_cells_x, n_cells_y;
    double plot_size;
    vector<vector<int>> grid;
    
    SpatialGrid(double plot_sz, double cell_sz) : 
        plot_size(plot_sz), cell_size(cell_sz) {
        n_cells_x = ceil(plot_size / cell_size);
        n_cells_y = ceil(plot_size / cell_size);
        grid.resize(n_cells_x * n_cells_y);
    }
    
    int getGridIndex(double x, double y) {
        int ix = min(n_cells_x - 1, (int)floor(x / cell_size));
        int iy = min(n_cells_y - 1, (int)floor(y / cell_size));
        return iy * n_cells_x + ix;
    }
    
    void addPoint(int point_id, double x, double y) {
        int idx = getGridIndex(x, y);
        grid[idx].push_back(point_id);
    }
    
    vector<int> getNearbyPoints(double x, double y, double radius) {
        vector<int> nearby;
        
        int cell_radius = ceil(radius / cell_size);
        int cx = floor(x / cell_size);
        int cy = floor(y / cell_size);
        
        for(int dx = -cell_radius; dx <= cell_radius; dx++) {
            for(int dy = -cell_radius; dy <= cell_radius; dy++) {
                int ix = cx + dx;
                int iy = cy + dy;
                
                if(ix >= 0 && ix < n_cells_x && iy >= 0 && iy < n_cells_y) {
                    int idx = iy * n_cells_x + ix;
                    nearby.insert(nearby.end(), grid[idx].begin(), grid[idx].end());
                }
            }
        }
        
        return nearby;
    }
};

// Fast canopy cover calculation using spatial indexing (for large plots)
// [[Rcpp::export]]
double calcCanopyCoverIndexedCpp(NumericVector x, NumericVector y, 
                                NumericVector crown_radius, 
                                double plot_size = 100.0, 
                                double grid_res = 0.5) {
    
    int n_trees = x.size();
    int n_cells = ceil(plot_size / grid_res);
    
    // Build spatial index with cell size ~= max crown radius
    double max_radius = *max_element(crown_radius.begin(), crown_radius.end());
    SpatialGrid tree_index(plot_size, max(2.0 * max_radius, 5.0));
    
    for(int i = 0; i < n_trees; i++) {
        tree_index.addPoint(i, x[i], y[i]);
    }
    
    // Coverage grid
    vector<bool> grid(n_cells * n_cells, false);
    
    // For each grid cell, check nearby trees only
    for(int xi = 0; xi < n_cells; xi++) {
        double cell_x = (xi + 0.5) * grid_res;
        
        for(int yi = 0; yi < n_cells; yi++) {
            double cell_y = (yi + 0.5) * grid_res;
            
            // Get trees that could possibly cover this cell
            vector<int> nearby = tree_index.getNearbyPoints(cell_x, cell_y, max_radius);
            
            // Check if any nearby tree covers this cell
            for(int idx : nearby) {
                double dx = cell_x - x[idx];
                double dy = cell_y - y[idx];
                double dist_sq = dx * dx + dy * dy;
                
                if(dist_sq <= crown_radius[idx] * crown_radius[idx]) {
                    grid[yi * n_cells + xi] = true;
                    break;  // Cell is covered, no need to check more trees
                }
            }
        }
    }
    
    // Count covered cells
    int covered = 0;
    for(bool cell : grid) {
        if(cell) covered++;
    }
    
    return (double)covered / (n_cells * n_cells);
}

// ==============================================================================
// PARALLEL-READY ENERGY CALCULATION
// ==============================================================================
// Decompose energy calculation into independent components for potential parallelization

// [[Rcpp::export]]
List calcEnergyComponentsCpp(NumericVector metrics, NumericVector targets,
                            NumericVector weights, IntegerVector component_ids) {
    int n = metrics.size();
    map<int, double> component_energies;
    
    for(int i = 0; i < n; i++) {
        int comp_id = component_ids[i];
        double diff = metrics[i] - targets[i];
        double energy = weights[i] * diff * diff;
        component_energies[comp_id] += energy;
    }
    
    // Convert to R list
    IntegerVector ids;
    NumericVector energies;
    
    for(auto& pair : component_energies) {
        ids.push_back(pair.first);
        energies.push_back(pair.second);
    }
    
    return List::create(Named("component_id") = ids,
                       Named("energy") = energies);
}
