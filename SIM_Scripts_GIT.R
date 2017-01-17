library(sp)
library(reshape2)
library(geojsonio)
library(rgdal)
library(downloader)
library(maptools)
library(XLConnect)
library(xlsx)
library(dplyr)
library(broom) # for writing model outputs to data frame

ug <- "http://geoportal.statistics.gov.uk/datasets/8edafbe3276d4b56aec60991cbddda50_2.geojson"
us <- "http://geoportal.statistics.gov.uk/datasets/8edafbe3276d4b56aec60991cbddda50_2.zip"
EW <- geojson_read("./tmp/EW.geojson", method="local", what = "sp", layer="OGRGeoJSON")

downloader::download(url = ug, destfile = "./tmp/EW.GeoJSON")
downloader::download(url = us, destfile = "./tmp/EW.zip")

unzip("./tmp/EW.zip", junkpaths = T, exdir="./tmp")

EW <- readOGR(dsn = "./tmp/Local_Authority_Districts_December_2015_Generalised_Clipped_Boundaries_in_Great_Britain.shp")
EW <- readOGR(dsn = "./tmp/EW.GeoJSON")


plot(EW)
head(EW@data)

#pull out london using grep
London <- EW[grep("^E09",EW@data$lad15cd),]
plot(London)
summary(London)

#transfrom to BNG
BNG = "+init=epsg:27700"
LondonBNG <- spTransform(London, BNG)
#order by borough name
LondonBNG <- LondonBNG[order(LondonBNG$lad15cd),]

LondonDF <- LondonBNG@data
centroids <- getSpPPolygonsLabptSlots(LondonBNG)
LondonDF <- cbind(LondonDF,centroids)
names(LondonDF)[7] <- "x"
names(LondonDF)[8] <- "y"

dist <- spDists(LondonBNG)
distPair <- melt(dist)

head(LondonBNG@data)
writePolyShape(LondonBNG, "London")

write.csv(dist, "LondonDistance.csv")
write.csv(LondonDF, "LondonDF.csv")

#read in London Commuting Data
cdata <- read.xlsx("LondonCommuting2001.xlsx", sheetIndex = "LondonCommuting2001", header = T)
CodeLookup <- read.csv("CodeLookup.csv")
popincome <- read.csv("popincome.csv")

cdata$OrigCodeNew <- CodeLookup$NewCode[match(cdata$OrigCodeNew, CodeLookup$OldCode)]
cdata$DestCodeNew <- CodeLookup$NewCode[match(cdata$DestCodeNew, CodeLookup$OldCode)]
cdata$vi1_origpop <- popincome$pop[match(cdata$OrigCodeNew, popincome$code)]
cdata$vi2_origsal <- popincome$med_income[match(cdata$OrigCodeNew, popincome$code)]
cdata$wj1_destpop <- popincome$pop[match(cdata$DestCodeNew, popincome$code)]
cdata$wj2_destsal <- popincome$med_income[match(cdata$DestCodeNew, popincome$code)]


#cdata$TotalNoIntra <- mutate(cdata, TotalNoIntra = ifelse(cdata$OrigCode == cdata$DestCode,0,cdata$Total))
cdata$TotalNoIntra <- ifelse(cdata$OrigCode == cdata$DestCode,0,cdata$Total)
cdata$dist <- distPair$value
cdata$offset <- ifelse(cdata$OrigCode == cdata$DestCode,0,1)

#run the models

#unconstrained (total contrained)

uncosim <- glm(TotalNoIntra ~ log(vi1_origpop)+log(wj2_destsal)+log(dist), na.action = na.exclude, family = poisson(link = "log"), data = cdatasub)
summary(uncosim)
cdatasub$ucoSim_fitted <- fitted(uncosim)
uncosim_out <- tidy(uncosim)

#production constrained

list <- cbind(lapply(cdata, class))

cdata1 <- cdata[cdata$OrigCode!=cdata$DestCode,]

#prodSim <- glm(TotalNoIntra ~ Orig+log(wj2_destsal)+dist, na.action = na.exclude, family = poisson(link = "log"), data = cdata1)
#summary(prodSim)
#cdata1$prodSim_fitted <- fitted(prodSim)

toMatch<-c("00AA", "00AB", "00AC", "00AD", "00AE", "00AF", "00AG")

#subset the data by the 7 sample boroughs
cdatasub <- cdata[grep(paste(toMatch,collapse = "|"), cdata$OrigCode),]
cdatasub <- cdatasub[grep(paste(toMatch,collapse = "|"), cdata$DestCode),]
cdatasub <- cdatasub[cdatasub$OrigCode!=cdatasub$DestCode,]
cdatasub <- cdatasub[1:42,]

prodSim <- glm(TotalNoIntra ~ Orig+log(wj2_destsal)+log(dist), na.action = na.exclude, family = poisson(link = "log"), data = cdatasub)
summary(prodSim)
prodsim_out <- tidy(prodSim)
cdatasub$prodSim_fitted <- fitted(prodSim)
R2 <- round(1- (prodSim$deviance / prodSim$null.deviance),2)
predict(prodSim)

write.csv(cdatasub, "cdata1.csv")

#attraction constrained

attrsim <- glm(TotalNoIntra ~ Dest+log(vi1_origpop)+log(dist), na.action = na.exclude, family = poisson(link = "log"), data = cdatasub)
summary(attrsim)
cdatasub$attrsim_fitted <- fitted(attrsim)
R2 <- round(1- (attrsim$deviance / attrsim$null.deviance),2)

write.csv(cdatasub, "cdata1.csv")

#doubly constrained

doubsim <- glm(TotalNoIntra ~ Orig+Dest+dist, na.action = na.exclude, family = poisson(link = "log"), data = cdatasub)
summary(doubsim)
cdatasub$doubsim_fitted <- fitted(doubsim)
R2 <- round(1- (doubsim$deviance / doubsim$null.deviance),2)

write.csv(cdatasub, "cdata1.csv")
write.csv(prodsim_out, "prodsim_out.csv")

