#install.packages("pscl")
library(pscl)
#install.packages("MASS")
library(MASS)
library(gdata)
library(readxl)


setwd("D://OneDrive - The Ohio State University/AAG/data") 
#Twitter <- read.xls("County_all.csv", header=T)
Twitter <- read_excel("County_all.xlsx",col_names = TRUE)
Twitter$GEOID <- as.factor(Twitter$GEOID)
Twitter$Tweetrate <- Twitter$Tweets/Twitter$POP16
names(Twitter)

hist(Twitter$Tweets)
hist(sqrt(Twitter$Tweets))
qqnorm(Twitter$Tweets)
qqnorm(sqrt(Twitter$Tweets))
qqnorm(log(Twitter$Tweets+1))
qqnorm(Twitter$Tweetrate)

############# use log(Tweetrate) ########
# replace zero with small value
Twitter$Tweetrate <- Twitter$Tweets/Twitter$POP16
index <- Twitter$Tweetrate == 0
Twitter$Tweetrate[index] <- 2e-3
qqnorm(log(Twitter$Tweetrate))
hist(log(Twitter$Tweetrate))
#######################################


library(sjPlot)
sjp.corr(Twitter[,c(3:23)])


# ols model
library(car) # calculate vif
# offset population
ols<-lm(Tweets~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF,data = Twitter, offset=POP16)
summary(ols)
vif(ols)
AIC(ols)
# no offset
ols3<-lm(Tweets~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF,data = Twitter)
summary(ols3)
AIC(ols3) #lowest
# population as IV
ols4<-lm(Tweets~POP16 + PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF,data = Twitter)
summary(ols4)
vif(ols4)
AIC(ols4)
# Tweetrate
ols2<-lm(log(Tweetrate)~ PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF,data = Twitter)
summary(ols2)
vif(ols2)
AIC(ols2) # r squared lower, more appropriate
logLik(ols2)

plot(ols2$fitted.values, ols2$residuals, main="Residuals vs. Fitted", xlab="Fitted values", ylab="Residuals", pch=19)
abline(h=0)
library(lmtest)
bptest(ols2)

# poisson
pois<-glm(Tweets~log(POP16) + PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, family="poisson", data= Twitter)
summary(pois)
vif(pois)
pois$deviance/pois$df.residual
logLik(pois)

# offset log(pop)
pois2<-glm(Tweets~ PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, family="poisson", offset = log(POP16), data= Twitter)
summary(pois2)
pois$deviance/pois$df.residual


qpois<-glm(Tweets~log(POP16)+PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, family="quasipoisson", data= Twitter)
summary(qpois)
qpois$deviance/qpois$df.residual

nb <- glm.nb(Tweets~log(POP16) + PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, data= Twitter)
summary(nb)
nb$deviance/nb$df.residual
logLik(nb)



library(rgdal)
library(sp)
library(rgeos)
Tweetcounty<-readOGR(dsn="D://OneDrive - The Ohio State University/AAG/data/cb_2016_us_county_20m", layer="cb_2016_us_county_20m")
Tweet.join <- merge(Tweetcounty, Twitter, by="GEOID")
Tweet.join <- spTransform(Tweet.join, CRS("+proj=lcc +lat_1=33 +lat_2=45 +lat_0=39 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"))
plot(Tweet.join)
coords <- SpatialPoints(gCentroid(Tweet.join,byid=TRUE))
plot(coords)
Twitter.spdf<-SpatialPointsDataFrame(coords, Twitter)
proj4string(Twitter.spdf) <- proj4string(Tweet.join)
library(spgwr)
plot(Twitter.spdf)
bw <- gwr.sel(Tweetrate~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, data=Twitter.spdf, method="aicc", adapt=TRUE,verbose=TRUE)
bw #0.3268805
spgwrabi <- gwr(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, data=Twitter.spdf, bandwidth=bw, hatmatrix=TRUE)
spgwrabi
# GWR
library(GWmodel)
DM<-gw.dist(dp.locat=coordinates(Twitter.spdf))



# First, we create two with adaptive kernels

Twitter.spdf$Tweetratestd=(Twitter.spdf$Tweetrate-mean(Twitter.spdf$Tweetrate))/sd(Twitter.spdf$Tweetrate)
# adaptive bisquare
bw.abi<-bw.gwr(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                data=Twitter.spdf, approach="AICc", kernel="bisquare", adaptive=TRUE, dMat=DM)
print(bw.abi)

gwr.abi<-gwr.basic(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                    data=Twitter.spdf, bw=bw.abi,  kernel="bisquare", adaptive=TRUE, dMat=DM)
print(gwr.abi)

mctest.abi<-montecarlo.gwr(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                            data=Twitter.spdf, nsims=99, kernel="bisquare", adaptive=TRUE, bw.abi)

# adaptive
bw.agau<-bw.gwr(Tweetrate~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
               data=Twitter.spdf, approach="AICc", kernel="gaussian", adaptive=TRUE, dMat=DM)
print(bw.agau)

gwr.agau<-gwr.basic(Tweetrate~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                   data=Twitter.spdf, bw=bw.agau,  kernel="gaussian", adaptive=TRUE, dMat=DM)
print(gwr.agau)

mctest.agau<-montecarlo.gwr(Tweetrate~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                           data=Twitter.spdf, nsims=99, kernel="gaussian", adaptive=TRUE, bw.agau)

writeGWR.shp(gwr.agau, fn="Twitter_GWR")

gwr.coll<-gwr.collin.diagno(Tweetrate~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                            data=Twitter.spdf, bw=bw.abi, kernel="gaussian", adaptive=TRUE, longlat = FALSE)
names(gwr.coll$SDF)


# log(tweet) adaptive bisquare
Twitter.spdf$logtweetrate <- log(Twitter.spdf$Tweetrate)
bw.abi.log<-bw.gwr(logtweetrate~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
               data=Twitter.spdf, approach="CV", kernel="gaussian", adaptive=TRUE, dMat=DM)
print(bw.abi.log)

gwr.abi.log<-gwr.basic(log(Tweetrate)~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                   data=Twitter.spdf, bw=bw.abi.log,  kernel="bisquare", adaptive=TRUE, dMat=DM)
print(gwr.abi.log)

mctest.abi.log<-montecarlo.gwr(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                           data=Twitter.spdf, nsims=99, kernel="bisquare", adaptive=TRUE, bw.abi.log)

# adaptive gaussian
bw.agau<-bw.gwr(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
               data=Twitter.spdf, approach="AICc", kernel="gaussian", adaptive=TRUE, dMat=DM)
print(bw.agau)

gwr.agau<-gwr.basic(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                   data=Twitter.spdf, bw=bw.agau,  kernel="gaussian", adaptive=TRUE, dMat=DM)
print(gwr.agau)

mctest.agau<-montecarlo.gwr(Tweetratestd~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                           data=Twitter.spdf, nsims=99, kernel="gaussian", adaptive=TRUE, bw.agau)



windows()
par(mfrow=c(3,2))
hist(gwr.coll$SDF$PCTPOV15_VIF, freq=T, main="VIF Poverty", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCTBD15_VIF, freq=T, main="VIF Bachelor Degree", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCT15_24_VIF, freq=T, main="VIF Age:15-24", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCT25_34_VIF, freq=T, main="VIF Age:25-34", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCT35_44_VIF, freq=T, main="VIF Age:35-44", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll$SDF$PCTHF_VIF, freq=T, main="VIF Hispanic Female", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)



# use log (twitter rate)
# Tweetrate
ols_log<-lm(log(Tweetrate)~PCTPOV15 +  PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44  + PCTHF,data = Twitter)
summary(ols_log)
vif(ols_log)
AIC(ols_log) # r squared lower, more appropriate
logLik(ols_log)


Tweet.join$resid_log<-resid(ols_log)
library(RColorBrewer)
library(classInt)
breaks.qt <- classIntervals(Tweet.join$resid_log, n = 7, style = "quantile", intervalClosure = "right")
brewpal<-brewer.pal(7,"RdYlBu")
spplot(Tweet.join, c("resid_log"), at=breaks.qt$brks, col.regions=brewpal, col = "transparent",
       main = "OLS Residuals")

# Let's begin by taking a look at the symmetry of the residuals:

me1 <- mean(residuals(ols_log))
me1    # Effectively zero
sd1 <- sd(residuals(ols_log))
sd1    # 0.6132837
summary(residuals(ols_log)) 
hist(residuals(ols_log), breaks=seq(-4.5, 4, .01), col=8, probability=T,
     ylab='Density', main='Histogram of Residuals(ols_log)',
     xlab='Residuals(ols_log)')
box()
curve(dnorm(x, mean=me1, sd=sd1), from=-4, to=4, add=T,
      col='red', lwd=2)
leg.txt <- c("Residuals(ols_log)", "Min. =        -4.27754",
             "Max.=         3.76479",
             "Mean =       0.000", "Median =   0.01452", "Std. dev. =  0.6132837")
legend (x=1.8, y=1.4, leg.txt, cex=1)

plot(ols_log$fitted.values, ols_log$residuals, main="Residuals vs. Fitted", xlab="Fitted values", ylab="Residuals", pch=19)
abline(h=0)
bptest(ols_log)# problems with heteroskedasticity


# adaptive
bw.abi.log<-bw.gwr(log(Tweetrate)~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
               data=Twitter.spdf, approach="AICc", kernel="gaussian", adaptive=TRUE, dMat=DM)
print(bw.abi.log) #1369

gwr.abi.log<-gwr.basic(log(Tweetrate)~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                   data=Twitter.spdf, bw=bw.abi.log,  kernel="gaussian", adaptive=TRUE, dMat=DM)
print(gwr.abi.log)

mctest.abi.log<-montecarlo.gwr(log(Tweetrate)~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                           data=Twitter.spdf, nsims=99, kernel="gaussian", adaptive=TRUE, bw.abi)

gwr.t.adj.log <- gwr.t.adjust(gwr.abi.log)

writeGWR.shp(gwr.abi.log, fn="Twitter_log_GWR")

gwr.coll.log<-gwr.collin.diagno(log(Tweetrate)~PCTPOV15 + PCTBD15 + PCT15_24 + PCT25_34 + PCT35_44 + PCTHF, 
                            data=Twitter.spdf, bw=bw.abi, kernel="bisquare", adaptive=TRUE, longlat = FALSE)
names(gwr.coll.log$SDF)


# map
names(gwr.abi.log$SDF)
Tweet.join <- merge(Tweet.join, gwr.abi.log$SDF@data)
Tweet.join <- merge(Tweet.join, gwr.t.adj.log$SDF@data)

mycol.1<-brewer.pal(6, "Greens")
mycol.2<-brewer.pal(4, "RdBu")

plot.pov<-spplot(Tweet.join, "PCTPOV15", col.regions=mycol.1, cuts=5, main="Parameter Values for Poverty")
plot.povt<-spplot(Tweet.join, "PCTPOV15_p_fb", col.regions=mycol.2, cuts=5, 
                  at = c(0, 0.025, 0.05, 0.1, 1.0000001), main="p-values for Poverty")

plot(plot.pov, split=c(1,1,2,1), more=T)
plot(plot.povt, split=c(2,1,2,1))



windows()
par(mfrow=c(3,2))
hist(gwr.coll.log$SDF$PCTPOV15_VIF, freq=T, main="VIF Poverty", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll.log$SDF$PCTBD15_VIF, freq=T, main="VIF Bachelor Degree", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll.log$SDF$PCT15_24_VIF, freq=T, main="VIF Age:15-24", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll.log$SDF$PCT25_34_VIF, freq=T, main="VIF Age:25-34", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll.log$SDF$PCT35_44_VIF, freq=T, main="VIF Age:35-44", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
hist(gwr.coll.log$SDF$PCTHF_VIF, freq=T, main="VIF Hispanic Female", xlab="VIF", xlim=c(1,6), ylim=c(0,1000))
abline(v=c(5,10), col=c("red","darkred"),lty=3, lwd=5)
