#include <Rcpp.h>
#include <cmath>
#include <vector>
#include <algorithm>

// Enable OpenMP if available
#ifdef _OPENMP
#include <omp.h>
#endif

using namespace Rcpp;
using namespace std;

// ==============================================================================
// PARALLEL CANOPY COVER CALCULATION (OpenMP)
// ==============================================================================
// Additional 2-4x speedup on multi-core systems for large plots

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
double calcCanopyCoverParallel(NumericVector x, NumericVector y, 
                              NumericVector crown_radius, 
                              double plot_size = 100.0, 
                              double grid_res = 0.5,
                              int n_threads = 0) {
    
    int n_trees = x.size();
    int n_cells = ceil(plot_size / grid_res);
    int total_cells = n_cells * n_cells;
    
    // Set number of threads (0 = automatic)
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #endif
    
    // Use vector<char> instead of vector<bool> for thread-safety
    // (vector<bool> has race conditions in parallel code)
    vector<char> grid(total_cells, 0);
    
    // Parallelize over grid cells (better than over trees to avoid race conditions)
    #ifdef _OPENMP
    #pragma omp parallel for collapse(2) schedule(dynamic)
    #endif
    for(int xi = 0; xi < n_cells; xi++) {
        for(int yi = 0; yi < n_cells; yi++) {
            double cell_x = (xi + 0.5) * grid_res;
            double cell_y = (yi + 0.5) * grid_res;
            int cell_idx = yi * n_cells + xi;
            
            // Check if any tree covers this cell
            for(int i = 0; i < n_trees; i++) {
                double dx = cell_x - x[i];
                double dy = cell_y - y[i];
                double dist_sq = dx * dx + dy * dy;
                
                if(dist_sq <= crown_radius[i] * crown_radius[i]) {
                    grid[cell_idx] = 1;
                    break;  // Cell is covered, no need to check more trees
                }
            }
        }
    }
    
    // Count covered cells (parallel reduction)
    int covered = 0;
    #ifdef _OPENMP
    #pragma omp parallel for reduction(+:covered)
    #endif
    for(int i = 0; i < total_cells; i++) {
        covered += grid[i];
    }
    
    return (double)covered / total_cells;
}

// ==============================================================================
// PARALLEL NEAREST NEIGHBOR CALCULATION
// ==============================================================================

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
NumericVector calcNearestDistanceParallel(NumericVector x1, NumericVector y1,
                                         NumericVector x2, NumericVector y2,
                                         int n_threads = 0) {
    int n1 = x1.size();
    int n2 = x2.size();
    NumericVector min_dist(n1);
    
    if(n2 == 0) {
        fill(min_dist.begin(), min_dist.end(), 1000.0);
        return min_dist;
    }
    
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #endif
    
    // Parallelize over trees in group 1
    #ifdef _OPENMP
    #pragma omp parallel for schedule(dynamic, 10)
    #endif
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
// PARALLEL ALLOMETRIC CALCULATIONS
// ==============================================================================

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
NumericVector calcCrownRadiusParallel(NumericVector dbh, IntegerVector species_idx,
                                     NumericMatrix params, int n_threads = 0) {
    int n = dbh.size();
    NumericVector radius(n);
    
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #pragma omp parallel for
    #endif
    for(int i = 0; i < n; i++) {
        int sp = species_idx[i] - 1;
        double a = params(sp, 0);
        double b = params(sp, 1);
        radius[i] = max(0.3, a + b * dbh[i]);
    }
    
    return radius;
}

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
NumericVector calcHeightParallel(NumericVector dbh, IntegerVector species_idx,
                                NumericMatrix params, int n_threads = 0) {
    int n = dbh.size();
    NumericVector height(n);
    
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #pragma omp parallel for
    #endif
    for(int i = 0; i < n; i++) {
        int sp = species_idx[i] - 1;
        double a = params(sp, 0);
        double b = params(sp, 1);
        height[i] = 1.3 + a * (1.0 - exp(-b * dbh[i]));
    }
    
    return height;
}

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
NumericVector calcCrownBaseHeightParallel(NumericVector dbh, NumericVector height,
                                         IntegerVector species_idx, NumericMatrix params,
                                         int n_threads = 0) {
    int n = dbh.size();
    NumericVector crown_base(n);
    
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #pragma omp parallel for
    #endif
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
// PARALLEL CLARK-EVANS CALCULATION (for very large plots)
// ==============================================================================

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
double calcCEParallel(double xmax, double ymax, NumericVector x, NumericVector y,
                     int n_threads = 0) {
    int na = x.size();
    vector<double> nearest_dist(na, 1e10);
    
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #endif
    
    // Find nearest neighbor for each point (parallel)
    #ifdef _OPENMP
    #pragma omp parallel for schedule(dynamic, 10)
    #endif
    for(int i = 0; i < na; i++) {
        double min_d = 1e10;
        
        for(int j = 0; j < na; j++) {
            if(i == j) continue;
            
            // Euclidean distance with toroidal edge correction
            double dx = fabs(x[i] - x[j]);
            double dy = fabs(y[i] - y[j]);
            dx = min(dx, xmax - dx);
            dy = min(dy, ymax - dy);
            double d = sqrt(dx * dx + dy * dy);
            
            if(d < min_d) {
                min_d = d;
            }
        }
        
        nearest_dist[i] = min_d;
    }
    
    // Calculate mean nearest neighbor distance
    double d1 = 0.0;
    for(int i = 0; i < na; i++) {
        d1 += nearest_dist[i];
    }
    d1 /= na;
    
    // Expected distance for random pattern
    double d1Poisson = 0.5 * sqrt((xmax * ymax) / na);
    
    return d1 / d1Poisson;
}

// ==============================================================================
// UTILITY: Check OpenMP availability and thread count
// ==============================================================================

// [[Rcpp::export]]
List getOpenMPInfo() {
    int max_threads = 1;
    bool available = false;
    
    #ifdef _OPENMP
    available = true;
    max_threads = omp_get_max_threads();
    #endif
    
    return List::create(
        Named("available") = available,
        Named("max_threads") = max_threads,
        Named("recommended_threads") = max(1, max_threads - 1)  // Leave one core free
    );
}

// ==============================================================================
// HYBRID PARALLEL CANOPY COVER (for very large plots)
// ==============================================================================
// Combines spatial indexing with OpenMP for maximum performance

// Simple grid-based spatial structure for parallel use
struct SimpleGrid {
    vector<vector<int>> cells;
    int nx, ny;
    double cell_size;
    double plot_size;
    
    SimpleGrid(double plot_sz, double cell_sz, int n_trees) : 
        plot_size(plot_sz), cell_size(cell_sz) {
        nx = ceil(plot_size / cell_size);
        ny = ceil(plot_size / cell_size);
        cells.resize(nx * ny);
    }
    
    void addTree(int tree_id, double x, double y) {
        int ix = min(nx - 1, (int)floor(x / cell_size));
        int iy = min(ny - 1, (int)floor(y / cell_size));
        cells[iy * nx + ix].push_back(tree_id);
    }
    
    vector<int> getNearby(double x, double y, double radius) {
        vector<int> nearby;
        int cell_radius = ceil(radius / cell_size);
        int cx = floor(x / cell_size);
        int cy = floor(y / cell_size);
        
        for(int dx = -cell_radius; dx <= cell_radius; dx++) {
            for(int dy = -cell_radius; dy <= cell_radius; dy++) {
                int ix = cx + dx;
                int iy = cy + dy;
                if(ix >= 0 && ix < nx && iy >= 0 && iy < ny) {
                    int idx = iy * nx + ix;
                    nearby.insert(nearby.end(), cells[idx].begin(), cells[idx].end());
                }
            }
        }
        return nearby;
    }
};

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::export]]
double calcCanopyCoverHybrid(NumericVector x, NumericVector y, 
                            NumericVector crown_radius, 
                            double plot_size = 100.0, 
                            double grid_res = 0.5,
                            int n_threads = 0) {
    
    int n_trees = x.size();
    int n_cells = ceil(plot_size / grid_res);
    
    // Build spatial index (not parallelized - relatively fast)
    double max_radius = *max_element(crown_radius.begin(), crown_radius.end());
    SimpleGrid tree_grid(plot_size, max(2.0 * max_radius, 5.0), n_trees);
    
    for(int i = 0; i < n_trees; i++) {
        tree_grid.addTree(i, x[i], y[i]);
    }
    
    #ifdef _OPENMP
    if(n_threads > 0) {
        omp_set_num_threads(n_threads);
    }
    #endif
    
    // Coverage grid
    vector<char> grid(n_cells * n_cells, 0);
    
    // Parallel loop over grid cells
    #ifdef _OPENMP
    #pragma omp parallel for collapse(2) schedule(dynamic)
    #endif
    for(int xi = 0; xi < n_cells; xi++) {
        for(int yi = 0; yi < n_cells; yi++) {
            double cell_x = (xi + 0.5) * grid_res;
            double cell_y = (yi + 0.5) * grid_res;
            
            // Get nearby trees using spatial index
            vector<int> nearby = tree_grid.getNearby(cell_x, cell_y, max_radius);
            
            // Check if any nearby tree covers this cell
            for(int idx : nearby) {
                double dx = cell_x - x[idx];
                double dy = cell_y - y[idx];
                
                if(dx * dx + dy * dy <= crown_radius[idx] * crown_radius[idx]) {
                    grid[yi * n_cells + xi] = 1;
                    break;
                }
            }
        }
    }
    
    // Count covered cells (parallel reduction)
    int covered = 0;
    #ifdef _OPENMP
    #pragma omp parallel for reduction(+:covered)
    #endif
    for(int i = 0; i < n_cells * n_cells; i++) {
        covered += grid[i];
    }
    
    return (double)covered / (n_cells * n_cells);
}
