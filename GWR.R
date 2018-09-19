########################################################################
###
### GEOGRAPHICALLY WEIGHTED REGRESSION MODELING IN R
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
###
######################################################################

ny<-readOGR(dsn=getwd(), layer="ny_leukemia")
summary(ny)
names(ny)

# GWR requires that the data be in a SpatialPointsDataFrame format.

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

qqPlot(CASES, distribution="norm",
       xlab='', main='Quantile Comparison Plot CASES',
       envelope=.95, labels=FALSE, las=0, pch=NA, lwd=2, col="red",
       line="quartiles")

# Now add the QQ-Plot in black

par(new=TRUE)
qqPlot(CASES, distribution="norm", envelope=FALSE, labels=FALSE,
       pch=1, cex=1, col="black")
par(new=FALSE)



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


########## NOW ON TO THE GWR REGRESSION MODELS

#####
##### FIRST, JUST THE BASIC MODEL:
#####

gwr.fbi<-gwr.basic(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                   data=ny, bw=bw.fbi, kernel="bisquare", adaptive=F) #, F123.test=T)
print(gwr.fbi)

# Let's also look at spatial nonstationarity in the
# parameters using a Monte Carlo simulation.

mctest.fbi<-montecarlo.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                       data=ny, nsims=999, kernel="bisquare", adaptive=F, bw.fbi)

# Now let's run it again with the gaussian adaptive bandwidth

gwr.abi<-gwr.basic(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                    data=ny, bw=bw.abi, kernel="bisquare", adaptive=T)
print(gwr.abi)

mctest.abi<-montecarlo.gwr(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                       data=ny, nsims=999, kernel="bisquare",adaptive=T, bw.abi)


# use the results in ArcGIS

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



gwr.coll<-gwr.collin.diagno(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                            data=ny, bw=bw.abi, kernel="bisquare", adaptive=T)
names(gwr.coll$SDF)


windows()
par(mfrow=c(3,1))
hist(gwr.coll$SDF$PCTAGE65P_VIF, freq=T, main="VIF Prop. Age 65+", xlab="VIF", xlim=c(1,2), ylim=c(0,200))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCTOWNHOME_VIF, freq=T, main="VIF Prop. Homeownership", xlab="VIF", xlim=c(1,2), ylim=c(0,200))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PEXPOSURE_VIF, freq=T, main="VIF Exposure to TCE Sites", xlab="VIF", xlim=c(1,2), ylim=c(0,200))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)


windows()
par(mfrow=c(3,1))
hist(abs(gwr.coll$SDF$Corr_PCTAGE65P.PEXPOSURE), probability=F, main="EXPOSURE-AGE65+", xlab="Corr Coeff |r|", xlim=c(0,1), ylim=c(0,100))
abline(v=.8, col="red",lty=3, lwd=3)
hist(abs(gwr.coll$SDF$Corr_PCTOWNHOME.PEXPOSURE), probability=F, main="EXPOSURE-OWNHOME", xlab="Corr Coeff |r|", xlim=c(0,1), ylim=c(0,100))
abline(v=.8, col="red",lty=3, lwd=3)
hist(abs(gwr.coll$SDF$Corr_PCTAGE65P.PCTOWNHOME), probability=F, main="OWNHOME-AGE65+", xlab="Corr Coeff |r|", xlim=c(0,1), ylim=c(0,100))
abline(v=.8, col="red",lty=3, lwd=3)


#####
##### NOW LET'S RUN THE ROBUST MODEL:
#####


gwr.rob<-gwr.robust(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE, 
                 data=ny, bw=bw.abi, kernel="bisquare", adaptive=T)
print(gwr.rob)



#####
##### FINALLY, LET'S TAKE A LOOK AT THE MIXED GWR MODEL:
#####


gwr.mix<-gwr.mixed(CASES~PCTAGE65P+PCTOWNHOME+PEXPOSURE,
                   fixed.vars=c("PCTAGE65P", "PCTOWNHOME"),
                   data=ny.spdf, bw=bw.abi, kernel="bisquare", adaptive=T, diagnostic=T)
print(gwr.mix)


