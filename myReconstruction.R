# Load required libraries
library(Rcpp)
library(data.table)
library(spatstat)
library(ggplot2)
library(gridExtra)

# Source the C++ utility functions
sourceCpp("NumericUtilities.cpp")

# Reconstruction function
# Enhanced version with density control and diameter distribution support
reconstruct_pattern <- function(CEtarget, 
                               SPPtarget, 
                               HtAttrs, 
                               Density, 
                               DBHWeibull = NULL,
                               xmax = 100, 
                               ymax = 100, 
                               maxSimSteps = 200000, 
                               coolingFactor = 0.9, 
                               energyAim = 5E-15, 
                               plotUpdateInterval = 100,
                               densityWeight = 1.0,
                               dbhWeight = 1.0,
                               minPoints = 10) {  # Minimum number of points to maintain
  # Initialize parameters
  # Calculate area in hectares
  areaHectares <- (xmax * ymax) / 10000
  
  # Target number of points based on density (trees per hectare)
  nTargetPoints <- round(Density * areaHectares)
  
  # Initialize with target number of points (no Poisson variation for better control)
  nPoints <- nTargetPoints
  
  species <- names(SPPtarget)
  sppProbs <- SPPtarget / sum(SPPtarget)
  
  # Default DBH parameters if not using Weibull
  DEFAULT_DBH_MEAN <- 30
  DEFAULT_DBH_SD <- 10
  
  # Helper function to generate diameter from Weibull
  generate_diameter <- function(n = 1) {
    if (is.null(DBHWeibull)) {
      return(rnorm(n, mean = DEFAULT_DBH_MEAN, sd = DEFAULT_DBH_SD))  # Default if not specified
    }
    # Generate from 3-parameter Weibull: location + scale * (-log(U))^(1/shape)
    u <- runif(n)
    DBHWeibull$location + DBHWeibull$scale * (-log(1 - u))^(1 / DBHWeibull$shape)
  }
  
  # Generate initial random points
  simData <- data.table(
    Number = seq_len(nPoints),
    x = runif(nPoints, min = 0, max = xmax),
    y = runif(nPoints, min = 0, max = ymax),
    Species = sample(species, nPoints, replace = TRUE, prob = sppProbs),
    Height = rnorm(nPoints, mean = HtAttrs$mean, sd = HtAttrs$sd),
    DBH = generate_diameter(nPoints)
  )
  
  # Calculate initial conditions
  CE <- calcCE(xmax, ymax, simData$x, simData$y)
  sppProportions <- table(factor(simData$Species, levels = species)) / nrow(simData)
  currentDensity <- nrow(simData) / areaHectares
  
  # Calculate initial energy
  E0 <- calcEnergy(CE, CEtarget) +
    sum((sppProportions - SPPtarget)^2) +
    (mean(simData$Height) - HtAttrs$mean)^2 +
    (sd(simData$Height) - HtAttrs$sd)^2 +
    densityWeight * ((currentDensity - Density) / Density)^2
  
  # Add DBH energy if Weibull parameters provided
  if (!is.null(DBHWeibull)) {
    dbhEnergy <- calcWeibullEnergy(simData$DBH, 
                                   DBHWeibull$shape, 
                                   DBHWeibull$scale, 
                                   DBHWeibull$location)
    E0 <- E0 + dbhWeight * dbhEnergy
  }
  
  # Initialize plot data
  plotData <- data.table(
    Iteration = integer(),
    Metric = character(),
    Value = numeric(),
    Target = numeric()
  )
  
  # Simulated annealing
  Te <- 0.00005
  j <- 1
  while (E0 > energyAim && j <= maxSimSteps) {
    # Randomly select a row index and modify it
    rowIndex <- sample(nrow(simData), 1)
    tz <- sample(1:3, 1)
    
    # Backup current state
    backup <- copy(simData[rowIndex])
    backupNrow <- nrow(simData)
    
    if (tz == 1 && nrow(simData) > minPoints) { # Remove a point (don't go below minimum)
      simData <- simData[-rowIndex]
    } else if (tz == 2) { # Add a new point
      newPoint <- data.table(
        Number = max(simData$Number, na.rm = TRUE) + 1,
        x = runif(1, min = 0, max = xmax),
        y = runif(1, min = 0, max = ymax),
        Species = sample(species, 1, prob = sppProbs),
        Height = rnorm(1, mean = HtAttrs$mean, sd = HtAttrs$sd),
        DBH = generate_diameter(1)
      )
      simData <- rbind(simData, newPoint)
    } else { # Modify an existing point
      simData[rowIndex, `:=`(
        x = runif(1, min = 0, max = xmax),
        y = runif(1, min = 0, max = ymax),
        Species = sample(species, 1, prob = sppProbs),
        Height = rnorm(1, mean = HtAttrs$mean, sd = HtAttrs$sd),
        DBH = generate_diameter(1)
      )]
    }
    
    # Recalculate energy
    CE <- calcCE(xmax, ymax, simData$x, simData$y)
    sppProportions <- table(factor(simData$Species, levels = species)) / nrow(simData)
    heightMean <- mean(simData$Height)
    heightSD <- sd(simData$Height)
    currentDensity <- nrow(simData) / areaHectares
    
    E1 <- calcEnergy(CE, CEtarget) +
      sum((sppProportions - SPPtarget)^2) +
      (heightMean - HtAttrs$mean)^2 +
      (heightSD - HtAttrs$sd)^2 +
      densityWeight * ((currentDensity - Density) / Density)^2
    
    # Add DBH energy if Weibull parameters provided
    if (!is.null(DBHWeibull)) {
      dbhEnergy <- calcWeibullEnergy(simData$DBH, 
                                     DBHWeibull$shape, 
                                     DBHWeibull$scale, 
                                     DBHWeibull$location)
      E1 <- E1 + dbhWeight * dbhEnergy
    }
    
    # Accept or reject the change
    Accepted <- TRUE
    if (E1 > E0) {
      if (Te > 0) {
        u <- runif(1)
        p <- exp((E0 - E1) / Te)
        if (u >= p) {
          Accepted <- FALSE
          # Restore the backup
          if (tz == 1) { # Was a removal - restore the removed row
            if (rowIndex == 1) {
              simData <- rbind(backup, simData)
            } else if (rowIndex > nrow(simData)) {
              simData <- rbind(simData, backup)
            } else {
              simData <- rbind(simData[1:(rowIndex-1)], backup, simData[rowIndex:nrow(simData)])
            }
          } else if (tz == 2) { # Was an addition - remove the added row
            simData <- simData[-nrow(simData)]
          } else { # Was a modification - restore the original values
            simData[rowIndex] <- backup
          }
        } else {
          E0 <- E1
        }
      } else {
        Accepted <- FALSE
        # Restore the backup
        if (tz == 1) { # Was a removal - restore the removed row
          if (rowIndex == 1) {
            simData <- rbind(backup, simData)
          } else if (rowIndex > nrow(simData)) {
            simData <- rbind(simData, backup)
          } else {
            simData <- rbind(simData[1:(rowIndex-1)], backup, simData[rowIndex:nrow(simData)])
          }
        } else if (tz == 2) { # Was an addition - remove the added row
          simData <- simData[-nrow(simData)]
        } else { # Was a modification - restore the original values
          simData[rowIndex] <- backup
        }
      }
    } else {
      E0 <- E1
    }
    
    # Update temperature and iteration
    Te <- Te * coolingFactor
    
    # Update plot data
    metricNames <- c("CE", paste0("SPP_", names(SPPtarget)), "mHT", "sdHT", "Density")
    metricValues <- c(CE, sppProportions, heightMean, heightSD, currentDensity)
    metricTargets <- c(CEtarget, SPPtarget, HtAttrs$mean, HtAttrs$sd, Density)
    
    if (!is.null(DBHWeibull)) {
      dbhParams <- estimateWeibullParams(simData$DBH)
      metricNames <- c(metricNames, "DBH_shape", "DBH_scale", "DBH_location")
      metricValues <- c(metricValues, dbhParams$shape, dbhParams$scale, dbhParams$location)
      metricTargets <- c(metricTargets, DBHWeibull$shape, DBHWeibull$scale, DBHWeibull$location)
    }
    
    plotData <- rbind(plotData, data.table(
      Iteration = j,
      Metric = metricNames,
      Value = metricValues,
      Target = metricTargets
    ))
    
    # Plot the current state
    if (j %% plotUpdateInterval == 0 || j == 1) { # Update plot based on user-specified interval
      p1 <- ggplot(plotData[Metric == "CE"], aes(x = Iteration, y = Value)) +
        geom_line(color = "blue") +
        geom_hline(yintercept = CEtarget, linetype = "dashed", color = "red") +
        labs(title = "Clark-Evans Index (CE)", y = "Value", x = "Iteration")
      
      p2 <- ggplot(plotData[grepl("SPP_", Metric)], aes(x = Iteration, y = Value, color = Metric)) +
        geom_line() +
        geom_hline(data = plotData[grepl("SPP_", Metric)], aes(yintercept = Target, color = Metric), linetype = "dashed") +
        labs(title = "Species Proportions (SPP)", y = "Proportion", x = "Iteration")
      
      p3 <- ggplot(plotData[Metric == "Density"], aes(x = Iteration, y = Value)) +
        geom_line(color = "blue") +
        geom_hline(yintercept = Density, linetype = "dashed", color = "red") +
        labs(title = "Density (trees/ha)", y = "Density", x = "Iteration")
      
      p4 <- ggplot(plotData[Metric == "mHT"], aes(x = Iteration, y = Value)) +
        geom_line(color = "blue") +
        geom_hline(yintercept = HtAttrs$mean, linetype = "dashed", color = "red") +
        labs(title = "Mean Height (mHT)", y = "Height", x = "Iteration")
      
      if (!is.null(DBHWeibull)) {
        p5 <- ggplot(plotData[Metric == "DBH_shape"], aes(x = Iteration, y = Value)) +
          geom_line(color = "blue") +
          geom_hline(yintercept = DBHWeibull$shape, linetype = "dashed", color = "red") +
          labs(title = "DBH Weibull Shape", y = "Shape", x = "Iteration")
        
        grid.arrange(p1, p2, p3, p4, p5, ncol = 2)
      } else {
        grid.arrange(p1, p2, p3, p4, ncol = 2)
      }
    }
    
    # Display current state
    dbhInfo <- ""
    if (!is.null(DBHWeibull)) {
      dbhParams <- estimateWeibullParams(simData$DBH)
      dbhInfo <- sprintf(" DBH(s=%.2f,sc=%.2f,l=%.2f)", 
                        dbhParams$shape, dbhParams$scale, dbhParams$location)
    }
    
    cat(sprintf(
      "Iteration: %d E0: %.6f CE: %.6f T: %.6e Accepted: %s SPP: %s mHT: %.2f sdHT: %.2f Density: %.2f%s\n",
      j, E0, CE, Te, Accepted,
      paste(sprintf("%s=%.2f", names(sppProportions), sppProportions), collapse = ", "),
      heightMean, heightSD, currentDensity, dbhInfo
    ))
    
    j <- j + 1
  }
  
  # Convert to spatstat point pattern
  simDataP <- ppp(simData$x, simData$y, window = owin(c(0, xmax), c(0, ymax)), 
                  marks = simData[, .(Species, Height, DBH)])
  
  # Print final summary
  cat("\n=== Final Pattern Summary ===\n")
  cat(sprintf("Total trees: %d\n", nrow(simData)))
  cat(sprintf("Density: %.2f trees/ha (target: %.2f)\n", currentDensity, Density))
  cat(sprintf("Clark-Evans Index: %.4f (target: %.4f)\n", CE, CEtarget))
  cat(sprintf("Mean Height: %.2f (target: %.2f)\n", heightMean, HtAttrs$mean))
  cat(sprintf("SD Height: %.2f (target: %.2f)\n", heightSD, HtAttrs$sd))
  
  if (!is.null(DBHWeibull)) {
    finalDBH <- estimateWeibullParams(simData$DBH)
    cat(sprintf("DBH Weibull Shape: %.4f (target: %.4f)\n", finalDBH$shape, DBHWeibull$shape))
    cat(sprintf("DBH Weibull Scale: %.4f (target: %.4f)\n", finalDBH$scale, DBHWeibull$scale))
    cat(sprintf("DBH Weibull Location: %.4f (target: %.4f)\n", finalDBH$location, DBHWeibull$location))
  }
  
  cat("Species proportions:\n")
  for (i in seq_along(sppProportions)) {
    cat(sprintf("  %s: %.4f (target: %.4f)\n", 
                names(sppProportions)[i], sppProportions[i], SPPtarget[i]))
  }
  
  return(list(pattern = simDataP, data = simData, plotData = plotData))
}

# Example usage 1: Basic usage (backward compatible)
CEtarget <- 1.60
SPPtarget <- c(Species1 = 0.4, Species2 = 0.3, Species3 = 0.3)
HtAttrs <- list(mean = 15, sd = 5)
Density <- 250  # Trees per hectare

# Basic reconstruction (without diameter distribution)
result1 <- reconstruct_pattern(CEtarget, SPPtarget, HtAttrs, Density, 
                               xmax = 100, ymax = 100,
                               plotUpdateInterval = 500, maxSimSteps = 10000)

# Example usage 2: With diameter distribution (3-parameter Weibull)
# Weibull parameters for diameter distribution
DBHWeibull <- list(
  shape = 2.5,      # Shape parameter (k)
  scale = 15.0,     # Scale parameter (lambda) 
  location = 5.0    # Location parameter (theta) - minimum DBH
)

# Advanced reconstruction with diameter distribution
result2 <- reconstruct_pattern(CEtarget, SPPtarget, HtAttrs, Density,
                               DBHWeibull = DBHWeibull,
                               xmax = 100, ymax = 100,
                               plotUpdateInterval = 500, 
                               maxSimSteps = 10000,
                               densityWeight = 2.0,  # Higher weight on density matching
                               dbhWeight = 1.5)      # Weight for DBH distribution matching

# Access results
# result2$pattern - spatstat ppp object
# result2$data - data.table with all tree attributes
# result2$plotData - convergence data for plotting