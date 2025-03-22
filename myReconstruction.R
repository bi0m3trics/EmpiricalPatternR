# Load required libraries
library(Rcpp)
library(data.table)
library(spatstat)
library(ggplot2)
library(gridExtra)

# Source the C++ utility functions
sourceCpp("numericUtilities.cpp")

# Reconstruction function
reconstruct_pattern <- function(CEtarget, SPPtarget, HtAttrs, Density, xmax = 100, ymax = 100, maxSimSteps = 200000, coolingFactor = 0.9, energyAim = 5E-15, plotUpdateInterval = 100) {
  # Initialize parameters
  nPoints <- rpois(1, Density * xmax * ymax)
  species <- names(SPPtarget)
  sppProbs <- SPPtarget / sum(SPPtarget)
  
  # Generate initial random points
  simData <- data.table(
    Number = seq_len(nPoints),
    x = runif(nPoints, min = 0, max = xmax),
    y = runif(nPoints, min = 0, max = ymax),
    Species = sample(species, nPoints, replace = TRUE, prob = sppProbs),
    Height = rnorm(nPoints, mean = HtAttrs$mean, sd = HtAttrs$sd)
  )
  
  # Calculate initial conditions
  CE <- calcCE(xmax, ymax, simData$x, simData$y)
  sppProportions <- table(factor(simData$Species, levels = species)) / nrow(simData)
  E0 <- calcEnergy(CE, CEtarget) +
    sum((sppProportions - SPPtarget)^2) +
    (mean(simData$Height) - HtAttrs$mean)^2 +
    (sd(simData$Height) - HtAttrs$sd)^2
  
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
    
    if (tz == 1) { # Remove a point
      simData <- simData[-rowIndex]
    } else if (tz == 2) { # Add a new point
      newPoint <- data.table(
        Number = max(simData$Number, na.rm = TRUE) + 1,
        x = runif(1, min = 0, max = xmax),
        y = runif(1, min = 0, max = ymax),
        Species = sample(species, 1, prob = sppProbs),
        Height = rnorm(1, mean = HtAttrs$mean, sd = HtAttrs$sd)
      )
      simData <- rbind(simData, newPoint)
    } else { # Modify an existing point
      simData[rowIndex, `:=`(
        x = runif(1, min = 0, max = xmax),
        y = runif(1, min = 0, max = ymax),
        Species = sample(species, 1, prob = sppProbs),
        Height = rnorm(1, mean = HtAttrs$mean, sd = HtAttrs$sd)
      )]
    }
    
    # Recalculate energy
    CE <- calcCE(xmax, ymax, simData$x, simData$y)
    sppProportions <- table(factor(simData$Species, levels = species)) / nrow(simData)
    heightMean <- mean(simData$Height)
    heightSD <- sd(simData$Height)
    
    E1 <- calcEnergy(CE, CEtarget) +
      sum((sppProportions - SPPtarget)^2) +
      (heightMean - HtAttrs$mean)^2 +
      (heightSD - HtAttrs$sd)^2
    
    # Accept or reject the change
    Accepted <- TRUE
    if (E1 > E0) {
      if (Te > 0) {
        u <- runif(1)
        p <- exp((E0 - E1) / Te)
        if (u >= p) {
          Accepted <- FALSE
          simData[rowIndex] <- backup
        } else {
          E0 <- E1
        }
      } else {
        Accepted <- FALSE
        simData[rowIndex] <- backup
      }
    } else {
      E0 <- E1
    }
    
    # Update temperature and iteration
    Te <- Te * coolingFactor
    
    # Update plot data
    plotData <- rbind(plotData, data.table(
      Iteration = j,
      Metric = c("CE", paste0("SPP_", names(SPPtarget)), "mHT", "sdHT"),
      Value = c(CE, sppProportions, heightMean, heightSD),
      Target = c(CEtarget, SPPtarget, HtAttrs$mean, HtAttrs$sd)
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
      
      p3 <- ggplot(plotData[Metric == "mHT"], aes(x = Iteration, y = Value)) +
        geom_line(color = "blue") +
        geom_hline(yintercept = HtAttrs$mean, linetype = "dashed", color = "red") +
        labs(title = "Mean Height (mHT)", y = "Height", x = "Iteration")
      
      p4 <- ggplot(plotData[Metric == "sdHT"], aes(x = Iteration, y = Value)) +
        geom_line(color = "blue") +
        geom_hline(yintercept = HtAttrs$sd, linetype = "dashed", color = "red") +
        labs(title = "Height SD (sdHT)", y = "SD", x = "Iteration")
      
      grid.arrange(p1, p2, p3, p4, ncol = 2)
    }
    
    # Display current state
    cat(sprintf(
      "Iteration: %d E0: %.6f CE: %.6f T: %.6e Accepted: %s SPP: %s mHT: %.2f sdHT: %.2f\n",
      j, E0, CE, Te, Accepted,
      paste(sprintf("%s=%.2f", names(sppProportions), sppProportions), collapse = ", "),
      heightMean, heightSD
    ))
    
    j <- j + 1
  }
  
  # Convert to spatstat point pattern
  simDataP <- ppp(simData$x, simData$y, window = owin(c(0, xmax), c(0, ymax)), marks = simData[, .(Species, Height)])
  
  return(simDataP)
}

# Example usage
CEtarget <- 1.60
SPPtarget <- c(Species1 = 0.4, Species2 = 0.3, Species3 = 0.3)
HtAttrs <- list(mean = 15, sd = 5)
Density <- 0.025

result <- reconstruct_pattern(CEtarget, SPPtarget, HtAttrs, Density, plotUpdateInterval = 100)