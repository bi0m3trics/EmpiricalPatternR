#include <Rcpp.h>
#include <RcppParallel.h>
#include <cmath>
#include <limits>
#include <vector>

using namespace Rcpp;
using namespace RcppParallel;

// Function to calculate the Euclidean distance in a toroidal space
double getEuclideanDistance(double xmax, double ymax, double x1, double y1, double x2, double y2) {
  double dx = std::fabs(x1 - x2);
  double dy = std::fabs(y1 - y2);
  dx = std::min(dx, xmax - dx);
  dy = std::min(dy, ymax - dy);
  return std::sqrt(dx * dx + dy * dy);
}

// Parallel worker for finding nearest neighbors
struct NeighborFinder : public Worker {
  const RVector<double> x, y;
  const double xmax, ymax;
  RMatrix<double> distances;
  
  NeighborFinder(const NumericVector x, const NumericVector y, double xmax, double ymax, NumericMatrix distances)
    : x(x), y(y), xmax(xmax), ymax(ymax), distances(distances) {}
  
  void operator()(std::size_t begin, std::size_t end) {
    for (std::size_t i = begin; i < end; i++) {
      for (std::size_t j = 0; j < x.size(); j++) {
        if (i != j) {
          double dist = getEuclideanDistance(xmax, ymax, x[i], y[i], x[j], y[j]);
          distances(i, j) = dist;
        } else {
          distances(i, j) = std::numeric_limits<double>::max(); // Ignore self-distance
        }
      }
    }
  }
};

// [[Rcpp::export]]
NumericVector findNeighboursParallel(NumericVector x, NumericVector y, double xmax, double ymax, int mi) {
  int n = x.size();
  NumericMatrix distances(n, n);
  
  // Parallel computation of distances
  NeighborFinder finder(x, y, xmax, ymax, distances);
  parallelFor(0, n, finder);
  
  // Extract the average distance to the `mi` nearest neighbors
  NumericVector avgDistances(n);
  for (int i = 0; i < n; i++) {
    std::vector<double> row(distances(i, _).begin(), distances(i, _).end());
    std::nth_element(row.begin(), row.begin() + mi, row.end());
    double sum = 0.0;
    for (int k = 0; k < mi; k++) {
      sum += row[k];
    }
    avgDistances[i] = sum / mi;
  }
  
  return avgDistances;
}

// [[Rcpp::export]]
double calcCE(double xmax, double ymax, NumericVector x, NumericVector y) {
  NumericVector avgDistances = findNeighboursParallel(x, y, xmax, ymax, 1);
  double d1 = mean(avgDistances);
  int na = x.size();
  double d1Poisson = 0.5 * std::sqrt((xmax * ymax) / na);
  return d1 / d1Poisson;
}

// [[Rcpp::export]]
double calcEnergy(double CEcurrent, double CEtarget) {
  return (CEcurrent - CEtarget) * (CEcurrent - CEtarget);
}