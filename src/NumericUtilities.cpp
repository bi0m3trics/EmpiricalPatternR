#include <Rcpp.h>
#include <cmath>
#include <vector>
#include <algorithm>
#include <queue>

using namespace Rcpp;
using namespace std;

double getEuclideanDistance(double xmax, double ymax, double x1, double y1, double x2, double y2) { // Illian et al. (2008), p. 184
	double dx=fabs(x1-x2);
	double dy=fabs(y1-y2);
	dx=min(dx, xmax-dx);
	dy=min(dy, ymax-dy);
	double dz=sqrt(dx*dx+dy*dy);
	return dz;
}

// Improved nearest neighbor search using priority queues for better performance
double findNeighbours(double xmax, double ymax, NumericVector x, NumericVector y, int mi) {
    int na = x.size();
    
    // Large dummy value for initialization (larger than any expected distance in plot)
    const double DUMMY_LARGE_DISTANCE = 1000.0;
    
    // Use vectors instead of VLA for better memory management
    // We need mi+1 slots to track the mi nearest neighbors (excluding self at distance 0)
    vector<priority_queue<double, vector<double>, less<double>>> distances(na);
    
    // Initialize each priority queue to track mi+1 nearest neighbors
    for(int i = 0; i < na; i++) {
        // Add dummy large values to ensure we always have something to compare
        for(int j = 0; j <= mi; j++) {
            distances[i].push(DUMMY_LARGE_DISTANCE);
        }
    }
    
    // Calculate all pairwise distances (optimized loop)
    for(int i = 0; i < na - 1; i++) {
        for(int j = i + 1; j < na; j++) {
            double d = getEuclideanDistance(xmax, ymax, x[i], y[i], x[j], y[j]);
            
            // Update distances for point i
            if(d < distances[i].top()) {
                distances[i].pop();
                distances[i].push(d);
            }
            
            // Update distances for point j
            if(d < distances[j].top()) {
                distances[j].pop();
                distances[j].push(d);
            }
        }
    }
    
    // Calculate mean nearest neighbor distance (mi-th nearest, which is index mi counting from 1)
    double d1 = 0;
    for(int i = 0; i < na; i++) {
        // Pop off the furthest neighbor to get to the mi-th nearest
        distances[i].pop();
        if(!distances[i].empty()) {
            d1 += distances[i].top();
        }
    }
    d1 /= na;
    
    return d1;
}

// [[Rcpp::export]]
double calcCE(double xmax, double ymax, NumericVector x, NumericVector y) {
	double d1=findNeighbours(xmax,ymax,x,y,1);
	int na = x.size();
	double d1Poisson=0.5*sqrt((xmax*ymax)/na);
	return d1/d1Poisson;
}

// [[Rcpp::export]]
double calcEnergy(double CEcurrent, double CEtarget) {
    return (CEcurrent-CEtarget)*(CEcurrent-CEtarget);
}

// Weibull PDF for 3-parameter Weibull distribution
// Parameters: shape (k), scale (lambda), location (theta)
double weibull3_pdf(double x, double shape, double scale, double location) {
    if (x < location) return 0.0;
    double z = (x - location) / scale;
    return (shape / scale) * pow(z, shape - 1.0) * exp(-pow(z, shape));
}

// Calculate Weibull distribution parameters from a sample
// [[Rcpp::export]]
List estimateWeibullParams(NumericVector x) {
    int n = x.size();
    if (n == 0) {
        return List::create(Named("shape") = 1.0,
                          Named("scale") = 1.0,
                          Named("location") = 0.0);
    }
    
    // Use method of moments for initial estimates
    double mean = 0.0, variance = 0.0, minVal = x[0];
    for (int i = 0; i < n; i++) {
        mean += x[i];
        if (x[i] < minVal) minVal = x[i];
    }
    mean /= n;
    
    for (int i = 0; i < n; i++) {
        variance += pow(x[i] - mean, 2.0);
    }
    variance /= (n - 1);
    
    // Simple estimates (location = min value with some buffer)
    double location = max(0.0, minVal - 0.1 * mean);
    double cv = sqrt(variance) / mean;
    
    // Approximate shape from coefficient of variation
    double shape = 1.0 / (cv + 0.1); // Simple approximation
    shape = max(0.5, min(shape, 5.0)); // Bound shape parameter
    
    // Approximate scale from mean and shape
    double scale = (mean - location) / tgamma(1.0 + 1.0 / shape);
    scale = max(0.1, scale); // Ensure positive scale
    
    return List::create(Named("shape") = shape,
                       Named("scale") = scale,
                       Named("location") = location);
}

// Calculate Kolmogorov-Smirnov statistic between sample and Weibull distribution
// [[Rcpp::export]]
double calcWeibullKS(NumericVector x, double shape, double scale, double location) {
    int n = x.size();
    if (n == 0) return 1.0;
    
    // Sort the data
    NumericVector sorted = clone(x);
    std::sort(sorted.begin(), sorted.end());
    
    double maxD = 0.0;
    for (int i = 0; i < n; i++) {
        double z = (sorted[i] - location) / scale;
        double cdf = (sorted[i] <= location) ? 0.0 : (1.0 - exp(-pow(z, shape)));
        double empirical_cdf = (i + 1.0) / n;
        double d = fabs(empirical_cdf - cdf);
        if (d > maxD) maxD = d;
    }
    
    return maxD;
}

// Calculate energy contribution from Weibull distribution mismatch
// [[Rcpp::export]]
double calcWeibullEnergy(NumericVector x, double targetShape, double targetScale, double targetLocation) {
    List params = estimateWeibullParams(x);
    double shape = params["shape"];
    double scale = params["scale"];
    double location = params["location"];
    
    // Energy based on parameter differences (normalized)
    double shapeError = pow((shape - targetShape) / targetShape, 2.0);
    double scaleError = pow((scale - targetScale) / targetScale, 2.0);
    double locationError = pow((location - targetLocation) / (targetScale + 1.0), 2.0);
    
    return shapeError + scaleError + locationError;
}

