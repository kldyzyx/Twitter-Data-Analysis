########################################################################
###
### GEOGRAPHICALLY WEIGHTED REGRESSION MODELING IN R
### IN THIS DEMO WE:
###     1. Read in the shape file
###     2. Remind ourselves about the OLS model & check the diagnostics
###     5. Run some GWR models:
###        a. GWR Basic
###        b. GWR Robust
###     6. Examine model parameters for spatial nonstationarity 
###     7. Examine models for local collinearities
###     8. Examine models for the influence of local outliers
###
########################################################################
#
# Set working directory:

setwd("C:\\Users\\ERoot\\Box Sync\\GEOG8104\\2016\\Example Code")

# Load the necessary packages:

library(RColorBrewer)
library(GWmodel)
library(maptools)
library(rgdal)
library(car)
library(spdep)
library(lmtest)

######################################################################
###
### READ IN THE SHAPE FILE
### This is a dataset that looks at the geographic distribution of 
### leukemia cases in an are of NY state. To see more info on the data
### type help(NY_data) after loading the spdep package.  This will bring
### up a metadata document for the dataset.
###
######################################################################

ny<-readOGR(dsn=getwd(), layer="ny_leukemia")
summary(ny)
names(ny)

# GWR requires that the data be in a SpatialPointsDataFrame format.  So,
# here I extract the x,y coordinates from the data, extract all the rest of
# the attributes, then merge them together into a SptialPointsDataFrame called
# ny.spdf.

coords <- SpatialPoints(ny[, c("X", "Y")])
ny1<-data.frame(ny)
ny.spdf<-SpatialPointsDataFrame(coords, ny1)

plot(ny.spdf)

attach(ny1)

####### TAKE A LOOK AT THE DATA AND SEE WHAT RELATIONSHIPS WE HAVE

2*sqrt(length(CASES))         # 33.52

hist(CASES, nclass=33, border=2) # Looks left skewed, but really we have 3 outliers

mean(CASES); median(CASES)

# Let's check for normality using a QQ plot.
# Let's plot them with the 95% confidence envelope.  First, plot the
# 95% confidence envelope for the qqPlot.  Here it is for
# the CASES variable using qqPlot {car}:

qqPlot(CASES, distribution="norm",
       xlab='', main='Quantile Comparison Plot CASES',
       envelope=.95, labels=FALSE, las=0, pch=NA, lwd=2, col="red",
       line="quartiles")

# Now add the QQ-Plot in black

par(new=TRUE)
qqPlot(CASES, distribution="norm", envelope=FALSE, labels=FALSE,
       pch=1, cex=1, col="black")
par(new=FALSE)

# This actually looks pretty good, with the exception of 3 outliers.
# We'll leave this alone for now because it provides a good case
# for the robust GWR we'll do later on.

####### RUN AN OLS REGRESSION MODEL
lm1<-lm(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, data=ny)
summary(lm1) # Looks like the main exposure variable isn't significant

####################################################################
###
### OLS RESIDUAL DIAGNOSTICS
###
####################################################################

# Let's begin by taking a look at the symmetry of the residuals:

hist(residuals(lm1), breaks=seq(-1.8, 4.2, .1), col=8, probability=T,
     ylab='Density', main='Histogram of Residuals(lm1)',
     xlab='Residuals(lm1)')
box()
curve(dnorm(x, mean=me1, sd=sd1), from=-2, to=2, add=T,
      col='red', lwd=2)
leg.txt <- c("Residuals(lm1)", "Min. =        -1.740",
             "Max.=         4.142",
             "Mean =       0.000", "Median =   -0.031", "Std. dev. =  0.654")
legend (x=2, y=.8, leg.txt, cex=.7)

# Histogram not too bad, but clear signs of some serious outliers.
# Appears to be pretty heavy in the right tail.

plot(fitted(lm1), residuals(lm1), xlab="Fitted y", ylab= "Residuals",
     main="Plot of Residuals against Fitted y")
abline(h=0)

bptest(lm1)       # Certainly problems with heteroskedasticity

ny.q<-nb2listw(poly2nb(ny))
moran.test(CASES, ny.q)   # 0.1965 - definitely evidence of SA
moran.test(lm1$resid, ny.q) # 0.078 - still there, but much better

# Let's look at the Moran's Plot

moran.plot(CASES, ny.q, xlab=NULL, labels=F, ylab=NULL, pch=1)
moran.plot(lm1$resid, ny.q, xlab=NULL, labels=F, ylab=NULL, pch=1)

# Finally, let's take a look at which type of spatial model we might want to run

lm.LMtests(lm1, ny.q, test=c("LMerr", "LMlag", "RLMerr",
                             "RLMlag", "SARMA"))

# Looks like the lag model is the way to go

#####################################################################
###
############ SPATIAL REGRESSION MODELS
###
#####################################################################

ny.lag <- lagsarlm(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, data=ny,
                   ny.q, method="eigen", quiet=FALSE)
summary(ny.lag)

# Not too much different from the OLS model, though the model fits better

#####################################################################
###
############ GEOGRAPHICALLY WEIGHTED REGRESSION MODELS
###
#####################################################################

# The first step in GWR is to comput the optimal bandwidth.  There are 
# two methods for this: CV and AICc minimization.  We also have the option
# to choose an adaptive bandwidth or a fixed one.  Finally, we can specify
# the mathematical form we'd like out kernel to take.

# The options for kernels in GWmodel package are: gaussian, exponential,
# bisquare, tricube, boxcar.  Most researchers agree it doesn't matter too
# much, but the most commonly used are gaussian, exponential and bisquare.

# In the code below, let's see how specifying different kernels changes the
# bandwidth estimate.

# First, we create two with fixed kernels
bw.fbi<-bw.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
           data=ny.spdf, approach="CV", kernel="bisquare", adaptive=F)
print(bw.fbi) # 167164

bw.fgau<-bw.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                data=ny, approach="CV", kernel="gaussian", adaptive=F)
print(bw.fgau) # 167128 really not that different from the bisquare

# Let's run the first one again, but using AICc as the selection
bw.fbi.aic<-bw.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
               data=ny, approach="AICc", kernel="bisquare", adaptive=F)
print(bw.fbi.aic) # 167171 again, not that different from the first one

# Here we create two with adaptive kernels
bw.abi<-bw.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
               data=ny, approach="CV", kernel="bisquare", adaptive=T)
print(bw.abi) # 126 this is the number of neighbors to include, not the distance

bw.agau<-bw.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                data=ny, approach="CV", kernel="gaussian", adaptive=T)
print(bw.agau) # 279 this is quite different from the bisquare

# So, there are some differences, especially with the adaptive kernel.
# For the purpose of our analyses, let's use the bisquare kernel, it's a
# favorite with many geographers


########## NOW ON TO THE GWR REGRESSION MODELS

#####
##### FIRST, JUST THE BASIC MODEL:
#####

gwr.fbi<-gwr.basic(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                   data=ny, bw=bw.fbi, kernel="bisquare", adaptive=F) #, F123.test=T)
print(gwr.fbi)

# Let's also look at spatial nonstationarity in the
# parameters using a Monte Carlo simulation.
# Patient!  MC tests can take a while to run!
mctest.fbi<-montecarlo.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                       data=ny, nsims=999, kernel="bisquare", adaptive=F, bw.fbi)

# The output shows results for an OLS regression, the GWR regression, and some diagnostics
# The MC test doesn't imply that there's any spatial non-stationarity here...

# Now let's run it again with the gaussian adaptive bandwidth

gwr.abi<-gwr.basic(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                    data=ny, bw=bw.abi, kernel="bisquare", adaptive=T)
print(gwr.abi)

mctest.abi<-montecarlo.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                       data=ny, nsims=999, kernel="bisquare",adaptive=T, bw.abi)

# So, BIG difference with the results here.  The analysis with the adaptive
# gaussian kernel shows a clear spatial nonstationary effect for PEXPOSURE
# which suggests that there is an effect of exposure in some locations, but not all
# What does this mean?  Why does it only show up with the adaptive kernel?

# If we want to use the results in ArcGIS, this is a nifty bit of code that writes out a
# shapefile with the GWR results.  Note that it only works with the gwr.basic() call

writeGWR.shp(gwr.abi, fn="NY_GWR")

# Otherwise, we're going to have to map things in R, which takes a bit more effort

# Let's  map the parameter values and the t-values side by side
names(gwr.abi$SDF)

# First let's make some color classes for our maps using Color Brewer
mycol.1<-brewer.pal(6, "Greens")
mycol.2<-brewer.pal(6, "RdBu")

plot.exp<-spplot(gwr.abi$SDF, "PEXPOSURE", col.regions=mycol.1, cuts=5, main="Parameter Values for Exposure")
plot.expt<-spplot(gwr.abi$SDF, "PEXPOSURE_TV", col.regions=mycol.2, cuts=5, main="t-values for Exposure")

plot(plot.exp, split=c(1,1,2,1), more=T)
plot(plot.expt, split=c(2,1,2,1))

plot.hown<-spplot(gwr.abi$SDF, "PCTOWNHOME", col.regions=mycol.1, cuts=6, main="Parameter Values for Home Owner")
plot.hownt<-spplot(gwr.abi$SDF, "PCTOWNHOME_TV", col.regions=mycol.2, cuts=6, main="t-values for Home Owner")

plot(plot.hown, split=c(1,1,2,1), more=T)
plot(plot.hownt, split=c(2,1,2,1))

plot.age<-spplot(gwr.abi$SDF, "PCTAGE65P", col.regions=mycol.1, cuts=6, main="Parameter Values for Prop 65+")
plot.aget<-spplot(gwr.abi$SDF, "PCTAGE65P_TV", col.regions=mycol.2, cuts=6, main="t-values for Prop 65+")

plot(plot.age, split=c(1,1,2,1), more=T)
plot(plot.aget, split=c(2,1,2,1))

# As a rule of thumb, |t|>1.93 signifies significance at the 95% confidence level
# and |t|>2.53 signifies sig. at the 99% confidence level

#####
##### NOW LET'S LOOK FOR LOCAL COLLINEARITIES:
#####

gwr.coll<-gwr.collin.diagno(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                            data=ny, bw=bw.abi, kernel="bisquare", adaptive=T)
names(gwr.coll$SDF)

# Once we've run the code, we can look at the VIF and local correlations.  
# Windows() opens a window outside of R to plot everything in.  You don't have to do this, but sometimes it works
# better when you're trying to put multiple plots in the same window.
# The par(mfrow=) command divides up the window into 3 rows, 1 column

windows()
par(mfrow=c(3,1))
hist(gwr.coll$SDF$PCTAGE65P_VIF, freq=T, main="VIF Prop. Age 65+", xlab="VIF", xlim=c(1,2), ylim=c(0,200))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCTOWNHOME_VIF, freq=T, main="VIF Prop. Homeownership", xlab="VIF", xlim=c(1,2), ylim=c(0,200))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PEXPOSURE_VIF, freq=T, main="VIF Exposure to TCE Sites", xlab="VIF", xlim=c(1,2), ylim=c(0,200))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)

# Note that I have graphed a vertical line at x=5 and 10, these are traditionally cutoff
# values which we need to pay attention to.  We don't have a problem with our data, so these
# lines don't even show up.

windows()
par(mfrow=c(3,1))
hist(abs(gwr.coll$SDF$Corr_PCTAGE65P.PEXPOSURE), probability=F, main="EXPOSURE-AGE65+", xlab="Corr Coeff |r|", xlim=c(0,1), ylim=c(0,100))
abline(v=.8, col="red",lty=3, lwd=3)
hist(abs(gwr.coll$SDF$Corr_PCTOWNHOME.PEXPOSURE), probability=F, main="EXPOSURE-OWNHOME", xlab="Corr Coeff |r|", xlim=c(0,1), ylim=c(0,100))
abline(v=.8, col="red",lty=3, lwd=3)
hist(abs(gwr.coll$SDF$Corr_PCTAGE65P.PCTOWNHOME), probability=F, main="OWNHOME-AGE65+", xlab="Corr Coeff |r|", xlim=c(0,1), ylim=c(0,100))
abline(v=.8, col="red",lty=3, lwd=3)

# Looking at these, we don't seem to have any problems with local collinearities, either.
# Fotheringham suggests looking at correlations of >0.8, which I've marked here with a 
# straight red line.

#####
##### NOW LET'S RUN THE ROBUST MODEL:
#####

# If we have outliers, we can run the robust regression.  The code is below.  However,
# this can take a VERY long time, so I'd recommend not running it until you have some time
# to dedicate to waiting around for the results

gwr.rob<-gwr.robust(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                 data=ny, bw=bw.abi, kernel="bisquare", adaptive=T)
print(gwr.rob)

# These robust estimates show that there's no longer any spatial nonstationarity in the
# variables.  What does this mean?  Remember that the robust estimates downweight the effect
# of local outliers.  My hunch is that a few very high values are driving all the variation
# across locations.

#####
##### FINALLY, LET'S TAKE A LOOK AT THE MIXED GWR MODEL:
#####

# Let's make the two variables that showed no spatial nonstationarity in the Leung test
# or the MC test fixed.

# For some reason, gwr.mixed requires a spatial POINTS data frame, so we use ny.spdf here 
# instead of the ny spatial polygons data frame.

gwr.mix<-gwr.mixed(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE,
                   fixed.vars=c("PCTAGE65P", "PCTOWNHOME"),
                   data=ny.spdf, bw=bw.abi, kernel="bisquare", adaptive=T, diagnostic=T)
print(gwr.mix)

# This, to me is the "correct" model since we know that the relationship between PCTAGE65P and PCTOWNHOME
# and CASES isn't spatially stationary.  Notice the output doesn't provide a p-value for the two
# fixed variables.  Nothing we can do about that, it's just not part of the programming

