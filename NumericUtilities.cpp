#include <Rcpp.h>
#include <cmath>

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

double findNeighbours(double xmax, double ymax, NumericVector x, NumericVector y, int mi) {
	double d=0;
	bool abort;
	int dummy=0;
	int k=0;
	/* Number of required neighbours. */
	dummy=mi;
    int na = x.size();
	double distance[na][mi];
	for(int i=0;i<na;i++)
		for(int j=0;j<dummy;j++)
			distance[i][j] = 1000;
	for(int i=0;i<na-1;i++) {
		for(int j=i+1;j<na;j++) {
			d=getEuclideanDistance(xmax,ymax,x[i],y[i],x[j],y[j]);
			abort=false;
			k=dummy-1;
			while(abort==false)
				if (k==-1)
					abort=true;
				else if (d<distance[i][k]) 
					k--;
				else abort=true;
			if(k<dummy-1) {
				for(int l=dummy-1;l>k+1;l--) 
					distance[i][l]=distance[i][l-1];
				distance[i][k+1]=d;
			}
			abort=false;
			k=dummy-1;
			while (abort==false)
				if(k==-1)
					abort=true;
				else if(d<distance[j][k]) 
					k--;
				else abort=true;
			if (k<dummy-1) {
				for (int l=dummy-1;l>k+1;l--) 
					distance[j][l]=distance[j][l-1];
				distance[j][k+1]=d;
			}
		}
	}
	double d1=0;
    for(int i=0;i<na;i++) 
		d1+=distance[i][1];
	d1/=na;
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

