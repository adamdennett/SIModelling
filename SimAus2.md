Modelling Population Flows Using Spatial Interaction Models
================
Adam Dennett
22 March 2018

Getting Started: Setting up R and Getting Your Data in Order
------------------------------------------------------------

I will assume that you already have R and RStudio installed on your computer and you already have a little bit of knowledge about both. If you don't, then download R, and then RStudio from <https://www.r-project.org/> and <https://www.rstudio.com/>. They are both cross-platform and free to download.

Open up R Studio and set up a new project working directory. Open a new R script and save it into your new working directory.

Check the file is in your working directory and R can see it...

``` r
getwd()
list.files(getwd())
```

Before we go any further, let's first get a few packages that will come in handy for wrangling our data, carrying out some analysis and producing some visualisations.

If you don't have the packages already, install them using this script:

``` r
install.packages(c("sf", "tidyverse", "tmap", "geojsonio", "sp", "reshape2", "stplanr", "leaflet", "broom"))

setwd("E:\\Users\\Adam\\Dropbox\\Lectures\\SpatialInteractionModelling\\SIModelling")
```

Now 'library' them into your working environment:

``` r
library(tidyverse)
library(sf)
library(tmap)
library(geojsonio)
library(sp)
library(reshape2)
library(stplanr)
library(leaflet)
library(broom)
```

**Check that all of these packages have been libraried successfully and you don't get any error messages - if they haven't libraried successfully, then we may run into some problems later on. Possible problems that I have seen already are**

**1. that rgdal can cause some problems on Macs - if this happens, try updating your version of R and RStudio and re-installing the packages. If you are still having problems, try these solutions suggested on Stack Overflow, [here](http://stackoverflow.com/questions/34333624/trouble-installing-rgdal): **

**2. If you are using a computer that uses chinese characters in the file system, you might need to download the zipfile of the package and install it into your package directory manually.**

### Setting up Some Spatial Data

As the name suggests, to run a spatial interaction model, you are going to need some spatial data and some data on interactions (flows). Let's start with some spatial data:

``` r
#here is a geojson of Greater Capital City Statistical Areas, so let's read it in as an 'sp' object
Aus <- geojson_read("https://www.dropbox.com/s/0fg80nzcxcsybii/GCCSA_2016_AUST_New.geojson?raw=1", what = "sp")

#now let's extract the data
Ausdata <- Aus@data

#here is a geojson of Greater Capital City Statistical Areas, so let's read it in as a 'simple features' object and set the coordinate reference system at the same time in case the file doesn't have one.
AusSF <- st_as_sf(Aus) %>% st_set_crs(4283) 
#view the file
AusSF
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["GCCSA_CODE"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["GCC_CODE16"],"name":[2],"type":["fctr"],"align":["left"]},{"label":["GCCSA_NAME"],"name":[3],"type":["fctr"],"align":["left"]},{"label":["STATE_CODE"],"name":[4],"type":["fctr"],"align":["left"]},{"label":["STATE_NAME"],"name":[5],"type":["fctr"],"align":["left"]},{"label":["AREA_SQKM"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["geometry"],"name":[7],"type":["S3: sfc_MULTIPOLYGON"],"align":["right"]}],"data":[{"1":"1RNSW","2":"1RNSW","3":"Rest of NSW","4":"1","5":"New South Wales","6":"788442.589","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"1GSYD","2":"1GSYD","3":"Greater Sydney","4":"1","5":"New South Wales","6":"12368.193","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"2GMEL","2":"2GMEL","3":"Greater Melbourne","4":"2","5":"Victoria","6":"9992.512","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"2RVIC","2":"2RVIC","3":"Rest of Vic.","4":"2","5":"Victoria","6":"217503.119","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"3RQLD","2":"3RQLD","3":"Rest of Qld","4":"3","5":"Queensland","6":"1714330.123","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"3GBRI","2":"3GBRI","3":"Greater Brisbane","4":"3","5":"Queensland","6":"15841.960","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"4RSAU","2":"4RSAU","3":"Rest of SA","4":"4","5":"South Australia","6":"981015.072","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"4GADE","2":"4GADE","3":"Greater Adelaide","4":"4","5":"South Australia","6":"3259.836","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"5GPER","2":"5GPER","3":"Greater Perth","4":"5","5":"Western Australia","6":"6416.222","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"5RWAU","2":"5RWAU","3":"Rest of WA","4":"5","5":"Western Australia","6":"2520230.017","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"6GHOB","2":"6GHOB","3":"Greater Hobart","4":"6","5":"Tasmania","6":"1695.359","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"6RTAS","2":"6RTAS","3":"Rest of Tas.","4":"6","5":"Tasmania","6":"66322.502","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"7RNTE","2":"7RNTE","3":"Rest of NT","4":"7","5":"Northern Territory","6":"1344930.422","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"7GDAR","2":"7GDAR","3":"Greater Darwin","4":"7","5":"Northern Territory","6":"3163.906","7":"<S3: sfc_MULTIPOLYGON>"},{"1":"8ACTE","2":"8ACTE","3":"Australian Capital Territory","4":"8","5":"Australian Capital Territory","6":"2358.172","7":"<S3: sfc_MULTIPOLYGON>"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

``` r
#now you may have noticed that the code order is a bit weird, so let's fix that and reorder
AusSF1 <- AusSF[order(AusSF$GCCSA_CODE),]
#now let's create an 'sp' object from our new ordered SF object
Aus <- as(AusSF1, "Spatial")
```

Check your boundaries have downloaded OK...

``` r
tmap_mode("plot")
qtm(AusSF)
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-5-1.png)

``` r
#and have a quick look at the top of the data file
```

### Calculating a distance matrix

In our spatial interaction model, space is one of the key predictor variables. In this example we will use a very simple Euclidean distance measure between the centroids of the Greater Capital City Statistical Areas as our measure of space.

Now, with some areas so huge, there are obvious potential issues with this (for example we could use the average distance to larger settlements in the noncity areas), however as this is just an example, we will proceed with a simple solution for now.

``` r
#use the spDists function to create a distance matrix
#first re-project into a projected (metres) coordinate system
AusProj <- spTransform(Aus,"+init=epsg:3112")
summary(AusProj)
```

    ## Object of class SpatialPolygonsDataFrame
    ## Coordinates:
    ##        min      max
    ## x -2083066  2346598
    ## y -4973093 -1115948
    ## Is projected: TRUE 
    ## proj4string :
    ## [+init=epsg:3112 +proj=lcc +lat_1=-18 +lat_2=-36 +lat_0=0
    ## +lon_0=134 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0
    ## +units=m +no_defs]
    ## Data attributes:
    ##    GCCSA_CODE   GCC_CODE16                        GCCSA_NAME   STATE_CODE
    ##  1GSYD  :1    1GSYD  :1    Australian Capital Territory:1    1      :2   
    ##  1RNSW  :1    1RNSW  :1    Greater Adelaide            :1    2      :2   
    ##  2GMEL  :1    2GMEL  :1    Greater Brisbane            :1    3      :2   
    ##  2RVIC  :1    2RVIC  :1    Greater Darwin              :1    4      :2   
    ##  3GBRI  :1    3GBRI  :1    Greater Hobart              :1    5      :2   
    ##  3RQLD  :1    3RQLD  :1    Greater Melbourne           :1    6      :2   
    ##  (Other):9    (Other):9    (Other)                     :9    (Other):3   
    ##               STATE_NAME   AREA_SQKM      
    ##  New South Wales   :2    Min.   :   1695  
    ##  Northern Territory:2    1st Qu.:   4838  
    ##  Queensland        :2    Median :  15842  
    ##  South Australia   :2    Mean   : 512525  
    ##  Tasmania          :2    3rd Qu.: 884729  
    ##  Victoria          :2    Max.   :2520230  
    ##  (Other)           :3

``` r
#now calculate the distances
dist <- spDists(AusProj)
dist 
```

    ##            [,1]      [,2]      [,3]      [,4]      [,5]      [,6]
    ##  [1,]       0.0  391437.9  682745.0  685848.4  707908.1 1386485.4
    ##  [2,]  391437.9       0.0  644760.8  571477.3  750755.8 1100378.3
    ##  [3,]  682745.0  644760.8       0.0  133469.9 1337408.0 1694648.9
    ##  [4,]  685848.4  571477.3  133469.9       0.0 1296766.5 1584991.5
    ##  [5,]  707908.1  750755.8 1337408.0 1296766.5       0.0  998492.1
    ##  [6,] 1386485.4 1100378.3 1694648.9 1584991.5  998492.1       0.0
    ##  [7,] 1112315.7  819629.7  657875.7  541576.5 1550134.5 1477964.9
    ##  [8,] 1462171.3 1082754.7 1212525.3 1081939.7 1655212.1 1192252.9
    ##  [9,] 3226086.3 2891531.5 2722337.4 2633416.1 3531418.0 2962834.0
    ## [10,] 2870995.7 2490287.4 2542772.5 2424001.8 2993729.9 2239419.3
    ## [11,] 1064848.2 1192833.0  603165.2  731624.1 1772756.1 2280386.7
    ## [12,]  999758.0 1096764.5  489273.6  615173.0 1705581.2 2176139.6
    ## [13,] 3062979.3 2699307.7 3113837.0 2981210.5 2780660.8 1782227.9
    ## [14,] 2323414.2 1945803.1 2323404.3 2190310.9 2143514.5 1183495.9
    ## [15,]  256289.3  412697.8  430815.8  452584.3  948547.6 1505884.6
    ##            [,7]      [,8]      [,9]     [,10]     [,11]     [,12]   [,13]
    ##  [1,] 1112315.7 1462171.3 3226086.3 2870995.7 1064848.2  999758.0 3062979
    ##  [2,]  819629.7 1082754.7 2891531.5 2490287.4 1192833.0 1096764.5 2699308
    ##  [3,]  657875.7 1212525.3 2722337.4 2542772.5  603165.2  489273.6 3113837
    ##  [4,]  541576.5 1081939.7 2633416.1 2424001.8  731624.1  615173.0 2981211
    ##  [5,] 1550134.5 1655212.1 3531418.0 2993729.9 1772756.1 1705581.2 2780661
    ##  [6,] 1477964.9 1192252.9 2962834.0 2239419.3 2280386.7 2176139.6 1782228
    ##  [7,]       0.0  602441.7 2120117.7 1884897.3 1170300.0 1049301.5 2584760
    ##  [8,]  602441.7       0.0 1879873.6 1408864.5 1765685.0 1644255.7 1991775
    ##  [9,] 2120117.7 1879873.6       0.0  963094.8 3030825.1 2933427.1 2648782
    ## [10,] 1884897.3 1408864.5  963094.8       0.0 3007005.8 2891500.6 1686415
    ## [11,] 1170300.0 1765685.0 3030825.1 3007005.8       0.0  121449.6 3707567
    ## [12,] 1049301.5 1644255.7 2933427.1 2891500.6  121449.6       0.0 3587637
    ## [13,] 2584759.7 1991775.4 2648782.4 1686414.7 3707567.5 3587636.5       0
    ## [14,] 1788551.3 1198930.8 2215369.4 1302498.1 2913873.5 2793570.5  796710
    ## [15,]  936272.3 1368380.0 3055551.0 2766083.4  835822.4  759587.0 3101577
    ##         [,14]     [,15]
    ##  [1,] 2323414  256289.3
    ##  [2,] 1945803  412697.8
    ##  [3,] 2323404  430815.8
    ##  [4,] 2190311  452584.3
    ##  [5,] 2143514  948547.6
    ##  [6,] 1183496 1505884.6
    ##  [7,] 1788551  936272.3
    ##  [8,] 1198931 1368380.0
    ##  [9,] 2215369 3055551.0
    ## [10,] 1302498 2766083.4
    ## [11,] 2913873  835822.4
    ## [12,] 2793570  759587.0
    ## [13,]  796710 3101576.8
    ## [14,]       0 2337203.6
    ## [15,] 2337204       0.0

``` r
#melt this matrix into a list of origin/destination pairs using melt. Melt in in the reshape2 package. Reshape2, dplyr and ggplot, together, are some of the best packages in R, so if you are not familiar with them, get googling and your life will be much better!
distPair <- melt(dist)
#convert metres into km
distPair$value <- distPair$value / 1000
head(distPair)
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Var1"],"name":[1],"type":["int"],"align":["right"]},{"label":["Var2"],"name":[2],"type":["int"],"align":["right"]},{"label":["value"],"name":[3],"type":["dbl"],"align":["right"]}],"data":[{"1":"1","2":"1","3":"0.0000"},{"1":"2","2":"1","3":"391.4379"},{"1":"3","2":"1","3":"682.7450"},{"1":"4","2":"1","3":"685.8484"},{"1":"5","2":"1","3":"707.9081"},{"1":"6","2":"1","3":"1386.4854"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

These distances are notionally in km - although you may notice that they are not 100% accurate. This is not a big problem for now as this is just an example, but for real applications, more accurate distances may be used.

Flow Data
---------

The data we are going to use to test our spatial interaction models with is migration data from the 2011 Australian Census. The Australian Census has usual address indicator on Census night (UAICP) and address one year ago and 5 years ago indicators. From these, one year and 5 year migration transitions can be recorded - here we will use the 5 year transitions.

As well as flow data, there are additional data on unemployment rates, weekly income and the percentage of people living in rented accommodation for each origin and destination. We will use these as destination attractiveness / mass term and origin emissiveness / mass term proxies in the models which follow.

These data can be read straight into R with the following command:

``` r
#read in your Australian Migration Data
mdata <- read_csv("https://www.dropbox.com/s/wi3zxlq5pff1yda/AusMig2011.csv?raw=1",col_names = TRUE)

head(mdata)
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Origin"],"name":[1],"type":["chr"],"align":["left"]},{"label":["Orig_code"],"name":[2],"type":["chr"],"align":["left"]},{"label":["Destination"],"name":[3],"type":["chr"],"align":["left"]},{"label":["Dest_code"],"name":[4],"type":["chr"],"align":["left"]},{"label":["Flow"],"name":[5],"type":["int"],"align":["right"]},{"label":["vi1_origpop"],"name":[6],"type":["int"],"align":["right"]},{"label":["wj1_destpop"],"name":[7],"type":["int"],"align":["right"]},{"label":["vi2_origunemp"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["wj2_destunemp"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["vi3_origmedinc"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["wj3_destmedinc"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["vi4_origpctrent"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["wj4_destpctrent"],"name":[13],"type":["dbl"],"align":["right"]}],"data":[{"1":"Greater Sydney","2":"1GSYD","3":"Greater Sydney","4":"1GSYD","5":"3395015","6":"4391673","7":"4391673","8":"5.74","9":"5.74","10":"780.64","11":"780.64","12":"31.77","13":"31.77"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of NSW","4":"1RNSW","5":"91031","6":"4391673","7":"2512952","8":"5.74","9":"6.12","10":"780.64","11":"509.97","12":"31.77","13":"27.20"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Melbourne","4":"2GMEL","5":"22601","6":"4391673","7":"3999981","8":"5.74","9":"5.47","10":"780.64","11":"407.95","12":"31.77","13":"27.34"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Vic","4":"2RVIC","5":"4416","6":"4391673","7":"1345717","8":"5.74","9":"5.17","10":"780.64","11":"506.58","12":"31.77","13":"24.08"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Brisbane","4":"3GBRI","5":"22888","6":"4391673","7":"2065998","8":"5.74","9":"5.86","10":"780.64","11":"767.08","12":"31.77","13":"33.19"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Qld","4":"3RQLD","5":"27445","6":"4391673","7":"2253723","8":"5.74","9":"6.22","10":"780.64","11":"446.48","12":"31.77","13":"32.57"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

Now to finish, we need to add in our distance data that we generated earlier and create a new column of total flows which excludes flows that occur within areas (we could keep the within-area (intra-area) flows in, but they can cause problems so for now we will just exclude them).

``` r
#First create a new total column which excludes intra-zone flow totals (well sets them to a very very small number for reasons you will see later...)
mdata$FlowNoIntra <- ifelse(mdata$Orig_code == mdata$Dest_code,0,mdata$Flow)
mdata$offset <- ifelse(mdata$Orig_code == mdata$Dest_code,0.0000000001,1)

#now we ordered our spatial data earlier so that our zones are in their code order. We can now easily join these data together with our flow data as they are in the correct order.
mdata$dist <- distPair$value 
#and while we are here, rather than setting the intra zonal distances to 0, we should set them to something small (most intrazonal moves won't occur over 0 distance)
mdata$dist <- ifelse(mdata$dist == 0,5,mdata$dist)
```

Let's have a quick look at what your spangly new data looks like:

``` r
head(mdata)
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Origin"],"name":[1],"type":["chr"],"align":["left"]},{"label":["Orig_code"],"name":[2],"type":["chr"],"align":["left"]},{"label":["Destination"],"name":[3],"type":["chr"],"align":["left"]},{"label":["Dest_code"],"name":[4],"type":["chr"],"align":["left"]},{"label":["Flow"],"name":[5],"type":["int"],"align":["right"]},{"label":["vi1_origpop"],"name":[6],"type":["int"],"align":["right"]},{"label":["wj1_destpop"],"name":[7],"type":["int"],"align":["right"]},{"label":["vi2_origunemp"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["wj2_destunemp"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["vi3_origmedinc"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["wj3_destmedinc"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["vi4_origpctrent"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["wj4_destpctrent"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["FlowNoIntra"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["offset"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["dist"],"name":[16],"type":["dbl"],"align":["right"]}],"data":[{"1":"Greater Sydney","2":"1GSYD","3":"Greater Sydney","4":"1GSYD","5":"3395015","6":"4391673","7":"4391673","8":"5.74","9":"5.74","10":"780.64","11":"780.64","12":"31.77","13":"31.77","14":"0","15":"1e-10","16":"5.0000"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of NSW","4":"1RNSW","5":"91031","6":"4391673","7":"2512952","8":"5.74","9":"6.12","10":"780.64","11":"509.97","12":"31.77","13":"27.20","14":"91031","15":"1e+00","16":"391.4379"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Melbourne","4":"2GMEL","5":"22601","6":"4391673","7":"3999981","8":"5.74","9":"5.47","10":"780.64","11":"407.95","12":"31.77","13":"27.34","14":"22601","15":"1e+00","16":"682.7450"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Vic","4":"2RVIC","5":"4416","6":"4391673","7":"1345717","8":"5.74","9":"5.17","10":"780.64","11":"506.58","12":"31.77","13":"24.08","14":"4416","15":"1e+00","16":"685.8484"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Brisbane","4":"3GBRI","5":"22888","6":"4391673","7":"2065998","8":"5.74","9":"5.86","10":"780.64","11":"767.08","12":"31.77","13":"33.19","14":"22888","15":"1e+00","16":"707.9081"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Qld","4":"3RQLD","5":"27445","6":"4391673","7":"2253723","8":"5.74","9":"6.22","10":"780.64","11":"446.48","12":"31.77","13":"32.57","14":"27445","15":"1e+00","16":"1386.4854"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

And this is what those flows look like on a map - quick and dirty style... Although first we'll remove the intra-zonal flows.

``` r
#remove intra-zonal flows
mdatasub <- mdata[mdata$Orig_code!=mdata$Dest_code,]
```

Now create a flow-line object and weight the lines according to the flow volumes...

``` r
#use the od2line function from RObin Lovelace's excellent stplanr package - remove all but the origin, destination and flow columns
mdatasub_skinny <- mdatasub[,c(2,4,5)]
travel_network <- od2line(flow = mdatasub_skinny, zones = Aus)
#convert the flows to WGS84
travel_networkwgs <- spTransform(travel_network,"+init=epsg:4326" )
#And the Australia Map
AusWGS <- spTransform(Aus,"+init=epsg:4326" )
#and set the line widths to some sensible value according to the flow
w <- mdatasub_skinny$Flow / max(mdatasub_skinny$Flow) * 10
#now plot it...
plot(travel_networkwgs, lwd = w)
plot(AusWGS, add=T)
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-11-1.png)

Or, if you want to be really cool - on a leaflet map...

``` r
#plot in leaflet
leaflet() %>% 
  addTiles() %>% 
  addPolylines(
  data = travel_networkwgs,
  weight = w)
```

    ## PhantomJS not found. You can install it with webshot::install_phantomjs(). If it is installed, please make sure the phantomjs executable can be found via the PATH variable.

<!--html_preserve-->

<script type="application/json" data-for="htmlwidget-8cfec02d845597c4573e">{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"addTiles","args":["//{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",null,null,{"minZoom":0,"maxZoom":18,"maxNativeZoom":null,"tileSize":256,"subdomains":"abc","errorTileUrl":"","tms":false,"continuousWorld":false,"noWrap":false,"zoomOffset":0,"zoomReverse":false,"opacity":1,"zIndex":null,"unloadInvisibleTiles":null,"updateWhenIdle":null,"detectRetina":false,"reuseTiles":false,"attribution":"&copy; <a href=\"http://openstreetmap.org\">OpenStreetMap<\/a> contributors, <a href=\"http://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA<\/a>"}]},{"method":"addPolylines","args":[[[[{"lng":[150.767244034657,146.954254313677],"lat":[-33.6875773325951,-32.1516661922819]}]],[[{"lng":[150.767244034657,145.129444590623],"lat":[-33.6875773325951,-37.7843686763516]}]],[[{"lng":[150.767244034657,144.263332243991],"lat":[-33.6875773325951,-36.8035849787716]}]],[[{"lng":[150.767244034657,152.668770351835],"lat":[-33.6875773325951,-27.4518795960052]}]],[[{"lng":[150.767244034657,144.4483228536],"lat":[-33.6875773325951,-22.5231983143789]}]],[[{"lng":[150.767244034657,138.71907271383],"lat":[-33.6875773325951,-34.920229081644]}]],[[{"lng":[150.767244034657,135.814989812825],"lat":[-33.6875773325951,-30.0628648209482]}]],[[{"lng":[150.767244034657,115.983828700501],"lat":[-33.6875773325951,-32.0782864248405]}]],[[{"lng":[150.767244034657,122.201181754666],"lat":[-33.6875773325951,-25.4550548254669]}]],[[{"lng":[150.767244034657,147.437382313596],"lat":[-33.6875773325951,-42.83083732739]}]],[[{"lng":[150.767244034657,146.555497860401],"lat":[-33.6875773325951,-41.9879323580316]}]],[[{"lng":[150.767244034657,131.108299740687],"lat":[-33.6875773325951,-12.5309214194925]}]],[[{"lng":[150.767244034657,133.374440553838],"lat":[-33.6875773325951,-19.4946664656568]}]],[[{"lng":[150.767244034657,149.002522659636],"lat":[-33.6875773325951,-35.4887643071144]}]],[[{"lng":[146.954254313677,150.767244034657],"lat":[-32.1516661922819,-33.6875773325951]}]],[[{"lng":[146.954254313677,145.129444590623],"lat":[-32.1516661922819,-37.7843686763516]}]],[[{"lng":[146.954254313677,144.263332243991],"lat":[-32.1516661922819,-36.8035849787716]}]],[[{"lng":[146.954254313677,152.668770351835],"lat":[-32.1516661922819,-27.4518795960052]}]],[[{"lng":[146.954254313677,144.4483228536],"lat":[-32.1516661922819,-22.5231983143789]}]],[[{"lng":[146.954254313677,138.71907271383],"lat":[-32.1516661922819,-34.920229081644]}]],[[{"lng":[146.954254313677,135.814989812825],"lat":[-32.1516661922819,-30.0628648209482]}]],[[{"lng":[146.954254313677,115.983828700501],"lat":[-32.1516661922819,-32.0782864248405]}]],[[{"lng":[146.954254313677,122.201181754666],"lat":[-32.1516661922819,-25.4550548254669]}]],[[{"lng":[146.954254313677,147.437382313596],"lat":[-32.1516661922819,-42.83083732739]}]],[[{"lng":[146.954254313677,146.555497860401],"lat":[-32.1516661922819,-41.9879323580316]}]],[[{"lng":[146.954254313677,131.108299740687],"lat":[-32.1516661922819,-12.5309214194925]}]],[[{"lng":[146.954254313677,133.374440553838],"lat":[-32.1516661922819,-19.4946664656568]}]],[[{"lng":[146.954254313677,149.002522659636],"lat":[-32.1516661922819,-35.4887643071144]}]],[[{"lng":[145.129444590623,150.767244034657],"lat":[-37.7843686763516,-33.6875773325951]}]],[[{"lng":[145.129444590623,146.954254313677],"lat":[-37.7843686763516,-32.1516661922819]}]],[[{"lng":[145.129444590623,144.263332243991],"lat":[-37.7843686763516,-36.8035849787716]}]],[[{"lng":[145.129444590623,152.668770351835],"lat":[-37.7843686763516,-27.4518795960052]}]],[[{"lng":[145.129444590623,144.4483228536],"lat":[-37.7843686763516,-22.5231983143789]}]],[[{"lng":[145.129444590623,138.71907271383],"lat":[-37.7843686763516,-34.920229081644]}]],[[{"lng":[145.129444590623,135.814989812825],"lat":[-37.7843686763516,-30.0628648209482]}]],[[{"lng":[145.129444590623,115.983828700501],"lat":[-37.7843686763516,-32.0782864248405]}]],[[{"lng":[145.129444590623,122.201181754666],"lat":[-37.7843686763516,-25.4550548254669]}]],[[{"lng":[145.129444590623,147.437382313596],"lat":[-37.7843686763516,-42.83083732739]}]],[[{"lng":[145.129444590623,146.555497860401],"lat":[-37.7843686763516,-41.9879323580316]}]],[[{"lng":[145.129444590623,131.108299740687],"lat":[-37.7843686763516,-12.5309214194925]}]],[[{"lng":[145.129444590623,133.374440553838],"lat":[-37.7843686763516,-19.4946664656568]}]],[[{"lng":[145.129444590623,149.002522659636],"lat":[-37.7843686763516,-35.4887643071144]}]],[[{"lng":[144.263332243991,150.767244034657],"lat":[-36.8035849787716,-33.6875773325951]}]],[[{"lng":[144.263332243991,146.954254313677],"lat":[-36.8035849787716,-32.1516661922819]}]],[[{"lng":[144.263332243991,145.129444590623],"lat":[-36.8035849787716,-37.7843686763516]}]],[[{"lng":[144.263332243991,152.668770351835],"lat":[-36.8035849787716,-27.4518795960052]}]],[[{"lng":[144.263332243991,144.4483228536],"lat":[-36.8035849787716,-22.5231983143789]}]],[[{"lng":[144.263332243991,138.71907271383],"lat":[-36.8035849787716,-34.920229081644]}]],[[{"lng":[144.263332243991,135.814989812825],"lat":[-36.8035849787716,-30.0628648209482]}]],[[{"lng":[144.263332243991,115.983828700501],"lat":[-36.8035849787716,-32.0782864248405]}]],[[{"lng":[144.263332243991,122.201181754666],"lat":[-36.8035849787716,-25.4550548254669]}]],[[{"lng":[144.263332243991,147.437382313596],"lat":[-36.8035849787716,-42.83083732739]}]],[[{"lng":[144.263332243991,146.555497860401],"lat":[-36.8035849787716,-41.9879323580316]}]],[[{"lng":[144.263332243991,131.108299740687],"lat":[-36.8035849787716,-12.5309214194925]}]],[[{"lng":[144.263332243991,133.374440553838],"lat":[-36.8035849787716,-19.4946664656568]}]],[[{"lng":[144.263332243991,149.002522659636],"lat":[-36.8035849787716,-35.4887643071144]}]],[[{"lng":[152.668770351835,150.767244034657],"lat":[-27.4518795960052,-33.6875773325951]}]],[[{"lng":[152.668770351835,146.954254313677],"lat":[-27.4518795960052,-32.1516661922819]}]],[[{"lng":[152.668770351835,145.129444590623],"lat":[-27.4518795960052,-37.7843686763516]}]],[[{"lng":[152.668770351835,144.263332243991],"lat":[-27.4518795960052,-36.8035849787716]}]],[[{"lng":[152.668770351835,144.4483228536],"lat":[-27.4518795960052,-22.5231983143789]}]],[[{"lng":[152.668770351835,138.71907271383],"lat":[-27.4518795960052,-34.920229081644]}]],[[{"lng":[152.668770351835,135.814989812825],"lat":[-27.4518795960052,-30.0628648209482]}]],[[{"lng":[152.668770351835,115.983828700501],"lat":[-27.4518795960052,-32.0782864248405]}]],[[{"lng":[152.668770351835,122.201181754666],"lat":[-27.4518795960052,-25.4550548254669]}]],[[{"lng":[152.668770351835,147.437382313596],"lat":[-27.4518795960052,-42.83083732739]}]],[[{"lng":[152.668770351835,146.555497860401],"lat":[-27.4518795960052,-41.9879323580316]}]],[[{"lng":[152.668770351835,131.108299740687],"lat":[-27.4518795960052,-12.5309214194925]}]],[[{"lng":[152.668770351835,133.374440553838],"lat":[-27.4518795960052,-19.4946664656568]}]],[[{"lng":[152.668770351835,149.002522659636],"lat":[-27.4518795960052,-35.4887643071144]}]],[[{"lng":[144.4483228536,150.767244034657],"lat":[-22.5231983143789,-33.6875773325951]}]],[[{"lng":[144.4483228536,146.954254313677],"lat":[-22.5231983143789,-32.1516661922819]}]],[[{"lng":[144.4483228536,145.129444590623],"lat":[-22.5231983143789,-37.7843686763516]}]],[[{"lng":[144.4483228536,144.263332243991],"lat":[-22.5231983143789,-36.8035849787716]}]],[[{"lng":[144.4483228536,152.668770351835],"lat":[-22.5231983143789,-27.4518795960052]}]],[[{"lng":[144.4483228536,138.71907271383],"lat":[-22.5231983143789,-34.920229081644]}]],[[{"lng":[144.4483228536,135.814989812825],"lat":[-22.5231983143789,-30.0628648209482]}]],[[{"lng":[144.4483228536,115.983828700501],"lat":[-22.5231983143789,-32.0782864248405]}]],[[{"lng":[144.4483228536,122.201181754666],"lat":[-22.5231983143789,-25.4550548254669]}]],[[{"lng":[144.4483228536,147.437382313596],"lat":[-22.5231983143789,-42.83083732739]}]],[[{"lng":[144.4483228536,146.555497860401],"lat":[-22.5231983143789,-41.9879323580316]}]],[[{"lng":[144.4483228536,131.108299740687],"lat":[-22.5231983143789,-12.5309214194925]}]],[[{"lng":[144.4483228536,133.374440553838],"lat":[-22.5231983143789,-19.4946664656568]}]],[[{"lng":[144.4483228536,149.002522659636],"lat":[-22.5231983143789,-35.4887643071144]}]],[[{"lng":[138.71907271383,150.767244034657],"lat":[-34.920229081644,-33.6875773325951]}]],[[{"lng":[138.71907271383,146.954254313677],"lat":[-34.920229081644,-32.1516661922819]}]],[[{"lng":[138.71907271383,145.129444590623],"lat":[-34.920229081644,-37.7843686763516]}]],[[{"lng":[138.71907271383,144.263332243991],"lat":[-34.920229081644,-36.8035849787716]}]],[[{"lng":[138.71907271383,152.668770351835],"lat":[-34.920229081644,-27.4518795960052]}]],[[{"lng":[138.71907271383,144.4483228536],"lat":[-34.920229081644,-22.5231983143789]}]],[[{"lng":[138.71907271383,135.814989812825],"lat":[-34.920229081644,-30.0628648209482]}]],[[{"lng":[138.71907271383,115.983828700501],"lat":[-34.920229081644,-32.0782864248405]}]],[[{"lng":[138.71907271383,122.201181754666],"lat":[-34.920229081644,-25.4550548254669]}]],[[{"lng":[138.71907271383,147.437382313596],"lat":[-34.920229081644,-42.83083732739]}]],[[{"lng":[138.71907271383,146.555497860401],"lat":[-34.920229081644,-41.9879323580316]}]],[[{"lng":[138.71907271383,131.108299740687],"lat":[-34.920229081644,-12.5309214194925]}]],[[{"lng":[138.71907271383,133.374440553838],"lat":[-34.920229081644,-19.4946664656568]}]],[[{"lng":[138.71907271383,149.002522659636],"lat":[-34.920229081644,-35.4887643071144]}]],[[{"lng":[135.814989812825,150.767244034657],"lat":[-30.0628648209482,-33.6875773325951]}]],[[{"lng":[135.814989812825,146.954254313677],"lat":[-30.0628648209482,-32.1516661922819]}]],[[{"lng":[135.814989812825,145.129444590623],"lat":[-30.0628648209482,-37.7843686763516]}]],[[{"lng":[135.814989812825,144.263332243991],"lat":[-30.0628648209482,-36.8035849787716]}]],[[{"lng":[135.814989812825,152.668770351835],"lat":[-30.0628648209482,-27.4518795960052]}]],[[{"lng":[135.814989812825,144.4483228536],"lat":[-30.0628648209482,-22.5231983143789]}]],[[{"lng":[135.814989812825,138.71907271383],"lat":[-30.0628648209482,-34.920229081644]}]],[[{"lng":[135.814989812825,115.983828700501],"lat":[-30.0628648209482,-32.0782864248405]}]],[[{"lng":[135.814989812825,122.201181754666],"lat":[-30.0628648209482,-25.4550548254669]}]],[[{"lng":[135.814989812825,147.437382313596],"lat":[-30.0628648209482,-42.83083732739]}]],[[{"lng":[135.814989812825,146.555497860401],"lat":[-30.0628648209482,-41.9879323580316]}]],[[{"lng":[135.814989812825,131.108299740687],"lat":[-30.0628648209482,-12.5309214194925]}]],[[{"lng":[135.814989812825,133.374440553838],"lat":[-30.0628648209482,-19.4946664656568]}]],[[{"lng":[135.814989812825,149.002522659636],"lat":[-30.0628648209482,-35.4887643071144]}]],[[{"lng":[115.983828700501,150.767244034657],"lat":[-32.0782864248405,-33.6875773325951]}]],[[{"lng":[115.983828700501,146.954254313677],"lat":[-32.0782864248405,-32.1516661922819]}]],[[{"lng":[115.983828700501,145.129444590623],"lat":[-32.0782864248405,-37.7843686763516]}]],[[{"lng":[115.983828700501,144.263332243991],"lat":[-32.0782864248405,-36.8035849787716]}]],[[{"lng":[115.983828700501,152.668770351835],"lat":[-32.0782864248405,-27.4518795960052]}]],[[{"lng":[115.983828700501,144.4483228536],"lat":[-32.0782864248405,-22.5231983143789]}]],[[{"lng":[115.983828700501,138.71907271383],"lat":[-32.0782864248405,-34.920229081644]}]],[[{"lng":[115.983828700501,135.814989812825],"lat":[-32.0782864248405,-30.0628648209482]}]],[[{"lng":[115.983828700501,122.201181754666],"lat":[-32.0782864248405,-25.4550548254669]}]],[[{"lng":[115.983828700501,147.437382313596],"lat":[-32.0782864248405,-42.83083732739]}]],[[{"lng":[115.983828700501,146.555497860401],"lat":[-32.0782864248405,-41.9879323580316]}]],[[{"lng":[115.983828700501,131.108299740687],"lat":[-32.0782864248405,-12.5309214194925]}]],[[{"lng":[115.983828700501,133.374440553838],"lat":[-32.0782864248405,-19.4946664656568]}]],[[{"lng":[115.983828700501,149.002522659636],"lat":[-32.0782864248405,-35.4887643071144]}]],[[{"lng":[122.201181754666,150.767244034657],"lat":[-25.4550548254669,-33.6875773325951]}]],[[{"lng":[122.201181754666,146.954254313677],"lat":[-25.4550548254669,-32.1516661922819]}]],[[{"lng":[122.201181754666,145.129444590623],"lat":[-25.4550548254669,-37.7843686763516]}]],[[{"lng":[122.201181754666,144.263332243991],"lat":[-25.4550548254669,-36.8035849787716]}]],[[{"lng":[122.201181754666,152.668770351835],"lat":[-25.4550548254669,-27.4518795960052]}]],[[{"lng":[122.201181754666,144.4483228536],"lat":[-25.4550548254669,-22.5231983143789]}]],[[{"lng":[122.201181754666,138.71907271383],"lat":[-25.4550548254669,-34.920229081644]}]],[[{"lng":[122.201181754666,135.814989812825],"lat":[-25.4550548254669,-30.0628648209482]}]],[[{"lng":[122.201181754666,115.983828700501],"lat":[-25.4550548254669,-32.0782864248405]}]],[[{"lng":[122.201181754666,147.437382313596],"lat":[-25.4550548254669,-42.83083732739]}]],[[{"lng":[122.201181754666,146.555497860401],"lat":[-25.4550548254669,-41.9879323580316]}]],[[{"lng":[122.201181754666,131.108299740687],"lat":[-25.4550548254669,-12.5309214194925]}]],[[{"lng":[122.201181754666,133.374440553838],"lat":[-25.4550548254669,-19.4946664656568]}]],[[{"lng":[122.201181754666,149.002522659636],"lat":[-25.4550548254669,-35.4887643071144]}]],[[{"lng":[147.437382313596,150.767244034657],"lat":[-42.83083732739,-33.6875773325951]}]],[[{"lng":[147.437382313596,146.954254313677],"lat":[-42.83083732739,-32.1516661922819]}]],[[{"lng":[147.437382313596,145.129444590623],"lat":[-42.83083732739,-37.7843686763516]}]],[[{"lng":[147.437382313596,144.263332243991],"lat":[-42.83083732739,-36.8035849787716]}]],[[{"lng":[147.437382313596,152.668770351835],"lat":[-42.83083732739,-27.4518795960052]}]],[[{"lng":[147.437382313596,144.4483228536],"lat":[-42.83083732739,-22.5231983143789]}]],[[{"lng":[147.437382313596,138.71907271383],"lat":[-42.83083732739,-34.920229081644]}]],[[{"lng":[147.437382313596,135.814989812825],"lat":[-42.83083732739,-30.0628648209482]}]],[[{"lng":[147.437382313596,115.983828700501],"lat":[-42.83083732739,-32.0782864248405]}]],[[{"lng":[147.437382313596,122.201181754666],"lat":[-42.83083732739,-25.4550548254669]}]],[[{"lng":[147.437382313596,146.555497860401],"lat":[-42.83083732739,-41.9879323580316]}]],[[{"lng":[147.437382313596,131.108299740687],"lat":[-42.83083732739,-12.5309214194925]}]],[[{"lng":[147.437382313596,133.374440553838],"lat":[-42.83083732739,-19.4946664656568]}]],[[{"lng":[147.437382313596,149.002522659636],"lat":[-42.83083732739,-35.4887643071144]}]],[[{"lng":[146.555497860401,150.767244034657],"lat":[-41.9879323580316,-33.6875773325951]}]],[[{"lng":[146.555497860401,146.954254313677],"lat":[-41.9879323580316,-32.1516661922819]}]],[[{"lng":[146.555497860401,145.129444590623],"lat":[-41.9879323580316,-37.7843686763516]}]],[[{"lng":[146.555497860401,144.263332243991],"lat":[-41.9879323580316,-36.8035849787716]}]],[[{"lng":[146.555497860401,152.668770351835],"lat":[-41.9879323580316,-27.4518795960052]}]],[[{"lng":[146.555497860401,144.4483228536],"lat":[-41.9879323580316,-22.5231983143789]}]],[[{"lng":[146.555497860401,138.71907271383],"lat":[-41.9879323580316,-34.920229081644]}]],[[{"lng":[146.555497860401,135.814989812825],"lat":[-41.9879323580316,-30.0628648209482]}]],[[{"lng":[146.555497860401,115.983828700501],"lat":[-41.9879323580316,-32.0782864248405]}]],[[{"lng":[146.555497860401,122.201181754666],"lat":[-41.9879323580316,-25.4550548254669]}]],[[{"lng":[146.555497860401,147.437382313596],"lat":[-41.9879323580316,-42.83083732739]}]],[[{"lng":[146.555497860401,131.108299740687],"lat":[-41.9879323580316,-12.5309214194925]}]],[[{"lng":[146.555497860401,133.374440553838],"lat":[-41.9879323580316,-19.4946664656568]}]],[[{"lng":[146.555497860401,149.002522659636],"lat":[-41.9879323580316,-35.4887643071144]}]],[[{"lng":[131.108299740687,150.767244034657],"lat":[-12.5309214194925,-33.6875773325951]}]],[[{"lng":[131.108299740687,146.954254313677],"lat":[-12.5309214194925,-32.1516661922819]}]],[[{"lng":[131.108299740687,145.129444590623],"lat":[-12.5309214194925,-37.7843686763516]}]],[[{"lng":[131.108299740687,144.263332243991],"lat":[-12.5309214194925,-36.8035849787716]}]],[[{"lng":[131.108299740687,152.668770351835],"lat":[-12.5309214194925,-27.4518795960052]}]],[[{"lng":[131.108299740687,144.4483228536],"lat":[-12.5309214194925,-22.5231983143789]}]],[[{"lng":[131.108299740687,138.71907271383],"lat":[-12.5309214194925,-34.920229081644]}]],[[{"lng":[131.108299740687,135.814989812825],"lat":[-12.5309214194925,-30.0628648209482]}]],[[{"lng":[131.108299740687,115.983828700501],"lat":[-12.5309214194925,-32.0782864248405]}]],[[{"lng":[131.108299740687,122.201181754666],"lat":[-12.5309214194925,-25.4550548254669]}]],[[{"lng":[131.108299740687,147.437382313596],"lat":[-12.5309214194925,-42.83083732739]}]],[[{"lng":[131.108299740687,146.555497860401],"lat":[-12.5309214194925,-41.9879323580316]}]],[[{"lng":[131.108299740687,133.374440553838],"lat":[-12.5309214194925,-19.4946664656568]}]],[[{"lng":[131.108299740687,149.002522659636],"lat":[-12.5309214194925,-35.4887643071144]}]],[[{"lng":[133.374440553838,150.767244034657],"lat":[-19.4946664656568,-33.6875773325951]}]],[[{"lng":[133.374440553838,146.954254313677],"lat":[-19.4946664656568,-32.1516661922819]}]],[[{"lng":[133.374440553838,145.129444590623],"lat":[-19.4946664656568,-37.7843686763516]}]],[[{"lng":[133.374440553838,144.263332243991],"lat":[-19.4946664656568,-36.8035849787716]}]],[[{"lng":[133.374440553838,152.668770351835],"lat":[-19.4946664656568,-27.4518795960052]}]],[[{"lng":[133.374440553838,144.4483228536],"lat":[-19.4946664656568,-22.5231983143789]}]],[[{"lng":[133.374440553838,138.71907271383],"lat":[-19.4946664656568,-34.920229081644]}]],[[{"lng":[133.374440553838,135.814989812825],"lat":[-19.4946664656568,-30.0628648209482]}]],[[{"lng":[133.374440553838,115.983828700501],"lat":[-19.4946664656568,-32.0782864248405]}]],[[{"lng":[133.374440553838,122.201181754666],"lat":[-19.4946664656568,-25.4550548254669]}]],[[{"lng":[133.374440553838,147.437382313596],"lat":[-19.4946664656568,-42.83083732739]}]],[[{"lng":[133.374440553838,146.555497860401],"lat":[-19.4946664656568,-41.9879323580316]}]],[[{"lng":[133.374440553838,131.108299740687],"lat":[-19.4946664656568,-12.5309214194925]}]],[[{"lng":[133.374440553838,149.002522659636],"lat":[-19.4946664656568,-35.4887643071144]}]],[[{"lng":[149.002522659636,150.767244034657],"lat":[-35.4887643071144,-33.6875773325951]}]],[[{"lng":[149.002522659636,146.954254313677],"lat":[-35.4887643071144,-32.1516661922819]}]],[[{"lng":[149.002522659636,145.129444590623],"lat":[-35.4887643071144,-37.7843686763516]}]],[[{"lng":[149.002522659636,144.263332243991],"lat":[-35.4887643071144,-36.8035849787716]}]],[[{"lng":[149.002522659636,152.668770351835],"lat":[-35.4887643071144,-27.4518795960052]}]],[[{"lng":[149.002522659636,144.4483228536],"lat":[-35.4887643071144,-22.5231983143789]}]],[[{"lng":[149.002522659636,138.71907271383],"lat":[-35.4887643071144,-34.920229081644]}]],[[{"lng":[149.002522659636,135.814989812825],"lat":[-35.4887643071144,-30.0628648209482]}]],[[{"lng":[149.002522659636,115.983828700501],"lat":[-35.4887643071144,-32.0782864248405]}]],[[{"lng":[149.002522659636,122.201181754666],"lat":[-35.4887643071144,-25.4550548254669]}]],[[{"lng":[149.002522659636,147.437382313596],"lat":[-35.4887643071144,-42.83083732739]}]],[[{"lng":[149.002522659636,146.555497860401],"lat":[-35.4887643071144,-41.9879323580316]}]],[[{"lng":[149.002522659636,131.108299740687],"lat":[-35.4887643071144,-12.5309214194925]}]],[[{"lng":[149.002522659636,133.374440553838],"lat":[-35.4887643071144,-19.4946664656568]}]]],null,null,{"lineCap":null,"lineJoin":null,"clickable":true,"pointerEvents":null,"className":"","stroke":true,"color":"#03F","weight":[10,2.48278059122716,0.48510946820314,2.51430831255287,3.01490700969999,0.639013083455087,0.0873328865990707,1.16158231811141,0.23376651909789,0.180597818325625,0.219265964341818,0.218057584778812,0.0913974360382727,1.17212817611583,5.8839296503389,1.36294229438323,1.43731256385187,2.33986224472982,3.86560622205622,0.397337170853885,0.174775625885687,0.548164910854544,0.362513868901803,0.106557106919621,0.206742757961574,0.24694884160341,0.158078017378695,1.73336555678835,1.70930781821577,1.21881556832288,7.71824982698202,1.43434654128813,1.77478001999319,0.661423031714471,0.142808493809801,1.11126978721534,0.282760817743406,0.234535487910712,0.280673616680032,0.22223198690556,0.109413276795817,0.518944095967308,0.277597741428744,1.31460711186299,5.27336841295822,0.475991695136821,1.1097318495897,0.380200151596709,0.242994144851754,0.379980446221617,0.285726840307148,0.0738210060309125,0.156430227065505,0.169942107633663,0.0787643769704826,0.148630686249739,1.35591172238029,1.76434401467632,1.4366534477266,0.466544364007865,9.29892014808142,0.335270402390395,0.0900792037877207,0.528611132471356,0.197515132207709,0.152255824938757,0.253320297481078,0.199053069833353,0.0998560929793147,0.344278322769167,1.27802616691017,2.93317661016577,1.34943041381507,0.831914402785864,8.17413848029792,0.414584042798607,0.192352055893047,0.723709505553053,0.515209104590744,0.164669178631455,0.339334951829596,0.343509353956345,0.235084751348442,0.342191121705793,0.59551141918687,0.386461754786831,0.967802177280267,0.349990662521559,0.598367589063066,0.678120640221463,2.82068745811866,0.420625940613637,0.134899100306489,0.0661313179026925,0.0957915435401127,0.203337324647648,0.101174325229867,0.21893640627918,0.0523997319594424,0.163790357131087,0.126220737990355,0.268150410299788,0.0900792037877207,0.28924212630862,2.41840691632521,0.115565027298393,0.148301128187101,0.0155990816315321,0.0472366556447803,0.0748096802188266,0.0536081115224484,0.0201030418209181,0.715800112049741,0.446661027562039,1.28846217222704,0.321758521822236,0.55816150542123,0.769627928947282,0.289022420933528,0.0952422801023827,4.53911304940075,0.111830035921829,0.198284101020531,0.142808493809801,0.0453691599564983,0.183014577451637,0.0784348189078446,0.246289725478134,0.163680504443541,0.199162922520899,0.124902505739803,0.475442431699092,0.0886511188496227,0.107875339170173,4.62985136931375,0.0304291944502422,0.127758675615999,0.119739429425141,0.0684382243411585,0.0281222880117762,0.134459689556305,0.109852687546001,0.331315705638738,0.0683283716536125,0.143577462622623,0.198174248332985,0.0585514824620184,0.0116443848798761,0.0987575661038547,0.0398765255791983,0.552009754918654,0.0208720106337402,0.0126330590677901,0.0620667684634905,0.112489152047105,0.204985114960838,0.289901242433896,0.179718996825257,0.169502696883479,0.31670529819512,0.0715140995924465,0.0375696191407323,0.132921751930661,0.113367973547473,0.792587140644396,0.0294405202623282,0.0186749568828201,0.0320769847634322,0.135997627181949,0.23925915347519,0.21454229877734,0.162581977568081,0.304182091814876,0.561127527984972,0.231239907284332,0.0704155727169865,0.236402983598994,0.104799463918885,0.0266942030736782,0.0368006503279103,0.219265964341818,0.0913974360382727,0.0446001911436763,0.157309048565873,0.0768968812822006,0.0870033285364326,0.0984280080412167,0.33153541101383,0.142369083059617,0.105568432731707,0.0767870285946546,0.0907383199129967,0.0105458580044161,0.0233986224472982,0.294844613373466,0.0251562654480342,0.731838604431457,1.69162153552087,0.574419703178038,0.132262635805385,0.47577198976173,0.434357526556887,0.149289802375015,0.0147202601311641,0.166316968944645,0.0313080159506102,0.0405356417044743,0.0296602256374202,0.0677791082158825,0.0231789170722062],"opacity":0.5,"fill":false,"fillColor":"#03F","fillOpacity":0.2,"dashArray":null,"smoothFactor":1,"noClip":false},null,null,null,null,null]}],"limits":{"lat":[-42.83083732739,-12.5309214194925],"lng":[115.983828700501,152.668770351835]}},"evals":[],"jsHooks":[]}</script>
<!--/html_preserve-->
Or you can view your flows as a matrix...

``` r
#now we can create pivot table to turn paired list into matrix (and compute the margins as well)
mdatasubmat <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "Flow", margins=c("Orig_code", "Dest_code"))
mdatasubmat
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["int"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["int"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["int"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["int"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["int"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["int"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["int"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["int"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["int"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["int"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["int"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["int"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["int"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["int"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["int"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["int"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"91031","4":"22601","5":"4416","6":"22888","7":"27445","8":"5817","9":"795","10":"10574","11":"2128","12":"1644","13":"1996","14":"1985","15":"832","16":"10670","17":"204822"},{"1":"1RNSW","2":"53562","3":"0","4":"12407","5":"13084","6":"21300","7":"35189","8":"3617","9":"1591","10":"4990","11":"3300","12":"970","13":"1882","14":"2248","15":"1439","16":"15779","17":"171358"},{"1":"2GMEL","2":"15560","3":"11095","4":"0","5":"70260","6":"13057","7":"16156","8":"6021","9":"1300","10":"10116","11":"2574","12":"2135","13":"2555","14":"2023","15":"996","16":"4724","17":"158572"},{"1":"2RVIC","2":"2527","3":"11967","4":"48004","5":"0","6":"4333","7":"10102","8":"3461","9":"2212","10":"3459","11":"2601","12":"672","13":"1424","14":"1547","15":"717","16":"1353","17":"94379"},{"1":"3GBRI","2":"12343","3":"16061","4":"13078","5":"4247","6":"0","7":"84649","8":"3052","9":"820","10":"4812","11":"1798","12":"1386","13":"2306","14":"1812","15":"909","16":"3134","17":"150407"},{"1":"3RQLD","2":"11634","3":"26701","4":"12284","5":"7573","6":"74410","7":"0","8":"3774","9":"1751","10":"6588","11":"4690","12":"1499","13":"3089","14":"3127","15":"2140","16":"3115","17":"162375"},{"1":"4GADE","2":"5421","3":"3518","4":"8810","5":"3186","6":"5447","7":"6173","8":"0","9":"25677","10":"3829","11":"1228","12":"602","13":"872","14":"1851","15":"921","16":"1993","17":"69528"},{"1":"4RSAU","2":"477","3":"1491","4":"1149","5":"2441","6":"820","7":"2633","8":"22015","9":"0","10":"1052","11":"1350","12":"142","13":"430","14":"681","15":"488","16":"183","17":"35352"},{"1":"5GPER","2":"6516","3":"4066","4":"11729","5":"2929","6":"5081","7":"7006","8":"2631","9":"867","10":"0","11":"41320","12":"1018","13":"1805","14":"1300","15":"413","16":"1666","17":"88347"},{"1":"5RWAU","2":"714","3":"2242","4":"1490","5":"1813","6":"1137","7":"4328","8":"807","9":"982","10":"42146","11":"0","12":"277","13":"1163","14":"1090","15":"623","16":"256","17":"59068"},{"1":"6GHOB","2":"1224","3":"1000","4":"3016","5":"622","6":"1307","7":"1804","8":"533","9":"106","10":"899","11":"363","12":"0","13":"5025","14":"190","15":"115","16":"565","17":"16769"},{"1":"6RTAS","2":"1024","3":"1866","4":"2639","5":"1636","6":"1543","7":"2883","8":"651","9":"342","10":"1210","11":"1032","12":"7215","13":"0","14":"268","15":"170","16":"292","17":"22771"},{"1":"7GDAR","2":"1238","3":"2178","4":"1953","5":"1480","6":"2769","7":"5108","8":"2105","9":"641","10":"2152","11":"954","12":"243","13":"335","14":"0","15":"1996","16":"832","17":"23984"},{"1":"7RNTE","2":"406","3":"1432","4":"700","5":"792","6":"896","7":"3018","8":"1296","9":"961","10":"699","11":"826","12":"96","13":"213","14":"2684","15":"0","16":"229","17":"14248"},{"1":"8ACTE","2":"6662","3":"15399","4":"5229","5":"1204","6":"4331","7":"3954","8":"1359","9":"134","10":"1514","11":"285","12":"369","13":"270","14":"617","15":"211","16":"0","17":"41538"},{"1":"(all)","2":"119308","3":"190047","4":"145089","5":"115683","6":"159319","7":"210448","8":"57139","9":"38179","10":"94040","11":"64449","12":"18268","13":"23365","14":"21423","15":"11970","16":"44791","17":"1313518"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

OK, we've set everything up, now it's...

Modellin' Time!
---------------

In explaining how to run and calibrate spatial interaction models in R, I will adopt the notation used by Taylor Oshan in his excellent primer for running spatial interation models in Python. The paper is well worth a read and can be found here: <http://openjournals.wu.ac.at/region/paper_175/175.html>

Below is the classic multiplicative gravity model:

1.  
    $$T\_{ij} = k \\frac{V\_i^\\mu W\_j^\\alpha}{d\_{ij}^\\beta}$$

This gravity model can be written in the form more familiar from Wilson's 1971 paper - <http://journals.sagepub.com/doi/abs/10.1068/a030001>

1.  
    *T*<sub>*i**j*</sub> = *k**V*<sub>*i*</sub><sup>*μ*</sup>*W*<sub>*j*</sub><sup>*α*</sup>*d*<sub>*i**j*</sub><sup>−</sup>*β*

**This model just says that the flows between an origin and destination are proportional to the product of the mass of the origin and destination and inversely proportional to the distance between them. **

**As origin and destination masses increase, flows increase, but as distance increases, flows decrease, and *vice versa*. **

-   where *T*<sub>*i**j*</sub> is the transition or flow, *T*, between origin *i* (always the rows in a matrix) and destination *j* (always the columns in a matrix). If you are not overly familiar with matrix notation, the *i* and *j* are just generic indexes to allow us to refer to any cell in the matrix more generally.

-   *V* is a vector (a 1 dimensional matrix - or, if you like, a single line of numbers) of origin attributes which relate to the emissiveness of all origins in the dataset, *i* - in our sample dataset, we have a vector of origin populations (which I have called vi1\_origpop) and a vector of origin average salaries (which I have called vi2\_origsal) in 2001

-   *W* is a vector of desination of attributes relating to the attractivenss of all destinations in the dataset, *j* - in our sample dataset, we have a vector of destination populations (which I have called wj1\_destpop) and a vector of destination average salaries (which I have called wj2\_destsal) in 2001

-   *d* is a matrix of costs relating to the flows between *i* and *j* - in our case the cost is distance and it is called 'dist' in our dataset.

-   *k*, *μ*, *α* and *β* are all model parameters to be estimated

*k* is a constant of proportionality and leads to this particular model being more accurately described as a 'total constrained' model as all flows estimated by the model will sum to any observed flow data used to calibrate the parameters, where:

1.  
    $$k = \\frac{T}{\\sum\_i \\sum\_jV\_i^\\mu  W\_j^\\alpha d\_{ij}^-\\beta }$$

and *T* is the sum of our matrix of observed flows or:

1.  
    *T* = ∑<sub>*i*</sub>∑<sub>*j*</sub>*T*<sub>*i**j*</sub>

In plain language, this is just the sum of all observed flows divided by the sum of all of the other elements in the model.

### Estimating Model Parameters

Now, it's perfectly possible to produce some flow estimates by plugging some arbitrary or expected estimated values into our parameters. The parameters relate to the scaling effect / importance of the variables they are associated with. Most simply, where the effects of origin and destination attributes on flows scale in a linear fashion (i.e. for a 1 unit increase in, say, population at origin, we might expect a 1 unit increase in flows of people from that origin, or for a halving in average salary at destination, we might expect a halving of commuters), *μ* = 1 and *α* = 1. In Newton's original gravity equation, *β* = -2 where the influence of distance on flows follows a power law - i.e. for a 1 unit increase in distance, we have a 1^-2 (1) unit decrease in flows, for a 2 unit increase in distance, we have 2^-2 (0.25 or 1/4) of the flows, for a 3 unit increase, 3^-2 (0.111) etc.

Let's see if these parameters are a fair first guess

``` r
#First plot the commuter flows against distance and then fit a model line with a ^-2 parameter
plot1 <- qplot(mdata$dist, mdata$Flow)
#and now the model fit...
options(scipen=10000)
plot1 + 
  stat_function(fun=function(x)x^-2, geom="line", aes(colour="^-2")) +
  labs(x = "Distance", y = "Migration Flow") +
  theme(legend.position="none")
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-14-1.png)

``` r
plot2 <- qplot(mdata$vi1_origpop, mdata$Flow)
plot2 + 
  stat_function(fun=function(x)x^1, geom="line", aes(colour="^1")) + 
  labs(x = "Origin Population", y = "Migration Flow") +
  theme(legend.position="none")
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-15-1.png)

``` r
plot3 <- qplot(mdata$wj3_destmedinc, mdata$Flow)
plot3 + 
  stat_function(fun=function(x)x^1, geom="line", aes(colour="^1")) +
  labs(x = "Destination Median Income", y = "Migration Flow") +
  theme(legend.position="none")
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-16-1.png)

OK, so it looks like we're not far off (well, destination income doesn't look too promising as a predictor, but we'll see how we get on...), so let's see what flow estimates with these starting parameters look like.

``` r
#set up some variables to hold our parameter values in:
mu <- 1
alpha <- 1
beta <- -2
k <- 1
T2 <- sum(mdatasub$Flow)
```

Now let's create some flow estimates using Equation 2 above... Begin by applying the parameters to the variables:

``` r
vi1_mu <- mdatasub$vi1_origpop^mu
wj3_alpha <- mdatasub$wj3_destmedinc^alpha
dist_beta <- mdatasub$dist^beta
T1 <- vi1_mu*wj3_alpha*dist_beta
k <- T2/sum(T1)
```

Then, just as in Equation 2 above, just multiply everything together to get your flow estimates:

``` r
#run the model and store all of the new flow estimates in a new column in the dataframe
mdatasub$unconstrainedEst1 <- round(k*vi1_mu*wj3_alpha*dist_beta,0)
#check that the sum of these estimates makes sense
sum(mdatasub$unconstrainedEst1)
```

    ## [1] 1313520

``` r
#turn it into a little matrix and have a look at your handy work
mdatasubmat1 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "unconstrainedEst1", margins=c("Orig_code", "Dest_code"))
mdatasubmat1
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"45500","4":"11964","5":"14723","6":"20926","7":"3175","8":"4923","9":"3342","10":"960","11":"1258","12":"5340","13":"7392","14":"1315","15":"1324","16":"183456","17":"305598"},{"1":"1RNSW","2":"39854","3":"0","4":"7676","5":"12134","6":"10646","7":"2884","8":"5188","9":"3488","10":"684","11":"957","12":"2435","13":"3515","14":"969","15":"1080","16":"40484","17":"131994"},{"1":"2GMEL","2":"20852","3":"15274","4":"0","5":"354079","6":"5340","7":"1936","8":"12818","9":"4427","10":"1228","11":"1461","12":"15158","13":"28111","14":"1159","15":"1206","16":"59134","17":"522183"},{"1":"2RVIC","2":"6952","3":"6541","4":"95930","5":"0","6":"1911","7":"744","8":"6363","9":"1871","10":"441","11":"541","12":"3466","13":"5982","14":"425","15":"456","16":"18027","17":"149650"},{"1":"3GBRI","2":"10018","3":"5819","4":"1467","5":"1937","6":"0","7":"2880","8":"1192","9":"1227","10":"377","11":"544","12":"906","13":"1195","14":"751","15":"732","16":"6300","17":"35345"},{"1":"3RQLD","2":"2849","3":"2955","4":"997","5":"1415","6":"5398","7":"0","8":"1431","9":"2580","10":"584","11":"1061","12":"598","13":"801","14":"1994","15":"2619","16":"2727","17":"28009"},{"1":"4GADE","2":"2406","3":"2895","4":"3595","5":"6587","6":"1218","7":"780","8":"0","9":"5493","10":"620","11":"814","12":"1233","13":"1872","14":"515","15":"623","16":"3835","17":"32486"},{"1":"4RSAU","2":"419","3":"499","4":"318","5":"496","6":"321","7":"360","8":"1407","9":"0","10":"237","11":"438","12":"163","13":"229","14":"261","15":"417","16":"540","17":"6105"},{"1":"5GPER","2":"404","3":"328","4":"296","5":"393","6":"331","7":"274","8":"533","9":"796","10":"0","11":"4401","12":"259","13":"338","14":"692","15":"573","16":"508","17":"10126"},{"1":"5RWAU","2":"148","3":"129","4":"99","5":"135","6":"134","7":"139","8":"196","9":"412","10":"1233","11":"0","12":"77","13":"101","14":"497","15":"482","16":"180","17":"3962"},{"1":"6GHOB","2":"454","3":"236","4":"739","5":"624","6":"161","7":"57","8":"214","9":"110","10":"52","11":"55","12":"0","13":"24141","14":"43","15":"41","16":"831","17":"27758"},{"1":"6RTAS","2":"687","3":"373","4":"1499","5":"1177","6":"232","7":"83","8":"356","9":"170","10":"75","11":"80","12":"26406","13":"0","14":"62","15":"59","16":"1344","17":"32603"},{"1":"7GDAR","2":"31","3":"26","4":"16","5":"21","6":"37","7":"53","8":"25","9":"49","10":"39","11":"100","12":"12","13":"16","14":"0","15":"309","16":"34","17":"768"},{"1":"7RNTE","2":"40","3":"37","4":"21","5":"29","6":"46","7":"89","8":"39","9":"101","10":"41","11":"124","12":"15","13":"19","14":"396","15":"0","16":"45","17":"1042"},{"1":"8ACTE","2":"13192","3":"3324","4":"2440","5":"2745","6":"946","7":"219","8":"564","9":"310","10":"87","11":"110","12":"704","13":"1040","14":"104","15":"106","16":"0","17":"25891"},{"1":"(all)","2":"98306","3":"83936","4":"127057","5":"396495","6":"47647","7":"13673","8":"35249","9":"24376","10":"6658","11":"11944","12":"56772","13":"74752","14":"9183","15":"10027","16":"317445","17":"1313520"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

How do the flow estimates compare with the original flows?

``` r
mdatasubmat
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["int"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["int"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["int"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["int"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["int"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["int"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["int"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["int"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["int"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["int"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["int"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["int"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["int"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["int"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["int"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["int"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"91031","4":"22601","5":"4416","6":"22888","7":"27445","8":"5817","9":"795","10":"10574","11":"2128","12":"1644","13":"1996","14":"1985","15":"832","16":"10670","17":"204822"},{"1":"1RNSW","2":"53562","3":"0","4":"12407","5":"13084","6":"21300","7":"35189","8":"3617","9":"1591","10":"4990","11":"3300","12":"970","13":"1882","14":"2248","15":"1439","16":"15779","17":"171358"},{"1":"2GMEL","2":"15560","3":"11095","4":"0","5":"70260","6":"13057","7":"16156","8":"6021","9":"1300","10":"10116","11":"2574","12":"2135","13":"2555","14":"2023","15":"996","16":"4724","17":"158572"},{"1":"2RVIC","2":"2527","3":"11967","4":"48004","5":"0","6":"4333","7":"10102","8":"3461","9":"2212","10":"3459","11":"2601","12":"672","13":"1424","14":"1547","15":"717","16":"1353","17":"94379"},{"1":"3GBRI","2":"12343","3":"16061","4":"13078","5":"4247","6":"0","7":"84649","8":"3052","9":"820","10":"4812","11":"1798","12":"1386","13":"2306","14":"1812","15":"909","16":"3134","17":"150407"},{"1":"3RQLD","2":"11634","3":"26701","4":"12284","5":"7573","6":"74410","7":"0","8":"3774","9":"1751","10":"6588","11":"4690","12":"1499","13":"3089","14":"3127","15":"2140","16":"3115","17":"162375"},{"1":"4GADE","2":"5421","3":"3518","4":"8810","5":"3186","6":"5447","7":"6173","8":"0","9":"25677","10":"3829","11":"1228","12":"602","13":"872","14":"1851","15":"921","16":"1993","17":"69528"},{"1":"4RSAU","2":"477","3":"1491","4":"1149","5":"2441","6":"820","7":"2633","8":"22015","9":"0","10":"1052","11":"1350","12":"142","13":"430","14":"681","15":"488","16":"183","17":"35352"},{"1":"5GPER","2":"6516","3":"4066","4":"11729","5":"2929","6":"5081","7":"7006","8":"2631","9":"867","10":"0","11":"41320","12":"1018","13":"1805","14":"1300","15":"413","16":"1666","17":"88347"},{"1":"5RWAU","2":"714","3":"2242","4":"1490","5":"1813","6":"1137","7":"4328","8":"807","9":"982","10":"42146","11":"0","12":"277","13":"1163","14":"1090","15":"623","16":"256","17":"59068"},{"1":"6GHOB","2":"1224","3":"1000","4":"3016","5":"622","6":"1307","7":"1804","8":"533","9":"106","10":"899","11":"363","12":"0","13":"5025","14":"190","15":"115","16":"565","17":"16769"},{"1":"6RTAS","2":"1024","3":"1866","4":"2639","5":"1636","6":"1543","7":"2883","8":"651","9":"342","10":"1210","11":"1032","12":"7215","13":"0","14":"268","15":"170","16":"292","17":"22771"},{"1":"7GDAR","2":"1238","3":"2178","4":"1953","5":"1480","6":"2769","7":"5108","8":"2105","9":"641","10":"2152","11":"954","12":"243","13":"335","14":"0","15":"1996","16":"832","17":"23984"},{"1":"7RNTE","2":"406","3":"1432","4":"700","5":"792","6":"896","7":"3018","8":"1296","9":"961","10":"699","11":"826","12":"96","13":"213","14":"2684","15":"0","16":"229","17":"14248"},{"1":"8ACTE","2":"6662","3":"15399","4":"5229","5":"1204","6":"4331","7":"3954","8":"1359","9":"134","10":"1514","11":"285","12":"369","13":"270","14":"617","15":"211","16":"0","17":"41538"},{"1":"(all)","2":"119308","3":"190047","4":"145089","5":"115683","6":"159319","7":"210448","8":"57139","9":"38179","10":"94040","11":"64449","12":"18268","13":"23365","14":"21423","15":"11970","16":"44791","17":"1313518"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

How good is my model?
---------------------

So, looking at the two little matrices above you can see that in some cases the flow estimates aren't too bad, but in others they are pretty rubbish. Whilst it's OK to eyeball small flow matrices like this, when you have much larger matrices, we need another solution...

### Testing the "goodness-of-fit".

Yes, that's what it's called - I know, it doesn't sound correct, but goodness-of-fit is the correct term for checking how well your model estimates match up with your observed flows.

So how do we do it?

Well... there are a number of ways but perhaps the two most common are to look at the coefficient of determination (*r*<sup>2</sup>) or the Square Root of Mean Squared Error (RMSE). You've probably come across *r*<sup>2</sup> before if you have fitted a linear regression model, but you may not have come across RMSE. There are other methods and they all do more or less the same thing, which is essentially to compare the modelled estimates with the real data. *r*<sup>2</sup> is popular as it is quite intuitive and can be compared across models. RMSE is less intuitive, but some argue is better for comparing changes to the same model. Here's we'll do both...

#### R-Squared

*r*<sup>2</sup> is the square of the correlation coefficient, *r*

For our sample data, we can calculate this very easily using a little function

``` r
CalcRSquared <- function(observed,estimated){
  r <- cor(observed,estimated)
  R2 <- r^2
  R2
}
CalcRSquared(mdatasub$Flow,mdatasub$unconstrainedEst1)
```

    ## [1] 0.1953717

Using this function we get a value of 0.18 or around 18%. This tells us that our model accounts for about 18% of the variation of flows in the system. Not bad, but not brilliant either.

#### Root Mean Squared Error (RMSE)

We can use a similar simple function to calculate the RMSE for our data

``` r
CalcRMSE <- function(observed,estimated){
  res <- (observed - estimated)^2
  RMSE <- round(sqrt(mean(res)),3)
  RMSE
}
CalcRMSE(mdatasub$Flow,mdatasub$unconstrainedEst1)
```

    ## [1] 25858.11

The figure that is produced by the RMSE calculation is far less intuitive than the *r*<sup>2</sup> value and this is mainly because it very much depends on things like the units the data are in and the volume of data. It can't be used to compare different models run using different data sets. However, it is good for assessing whether changes to the model result in improvements. The closer to 0 the RMSE value, the better the model.

So how can we start to improve our fit...?

Improving our model: 1 - Calibrating parameters
-----------------------------------------------

### (this bit might take a little while, but stick with it)

Now, the model we have run above is probably the most simple spatial interaction model we could have run and the results aren't terrible, but they're not great either.

One way that we can improve the fit of the model is by calibrating the parameters on the flow data that we have.

The traditional way that this has been done computationally is by using the goodness-of-fit statistics. If you have the requisite programming skills, you can write a computer algorithm that iteratively adjusts each parameter, runs the model, checks the goodness-of-fit and then starts all over again until the goodness-of-fit statistic is maximised.

This is partly why spatial interaction modelling was the preserve of specialists for so long as acquiring the requisite skills to write such computer programmes can be challenging!

However, since the early days of spatial interaction modelling, a number of useful developments have occurred... For a more detailed explanation, read the accompanying paper, but I will skate over them again here.

The mathematically minded among you may have noticed that if you take the logarithms of both sides of Equation 2, you end up with the following equation:

1.  
    ln*T*<sub>*i**j*</sub> = *k* + *μ*ln*V*<sub>*i*</sub> + *α*ln*W*<sub>*j*</sub> − *β*ln*d*<sub>*i**j*</sub>

Those of you who have played around with regression models in the past will realise that this is exactly that - a regression model.

And if you have played around with regression models you will be aware that there are various pieces of software available to run regressions (such as R) and calibrate the parameters for us, so we don't have to be expert programmers to do this - yay!

Now, there are a couple of papers that are worth reading at this point. Perhaps the best is by Flowerdew and Aitkin (1982), titled "A METHOD OF FITTING THE GRAVITY MODEL BASED ON THE POISSON DISTRIBUTION" - the paper can be found here: <http://onlinelibrary.wiley.com/doi/10.1111/j.1467-9787.1982.tb00744.x/abstract>

One of the key points that Flowerdew and Aitkin make is that the model in Equation 5 (known as a log-normal model) has various problems associated with it which mean that the estimates produced might not be reliable. If you'd like to know more about these, read the paper (and also Wilson's 1971 paper), but at this point it is worth just knowing that the way around many of these issues is to re-specify the model, not as a log-normal regression, but as a Poisson or negative binomial regression model.

### Poisson regression

Again, I go into this in more detail in the accompanying paper, but the main theory (for non-experts like me anyway) behind the Poisson regression model is that the sorts of flows that spatial interaction models deal with (such as migration or commuting flows) relate to non-negative integer counts (you can't have negative people moving between places and you can't - normally, if they are alive - have fractions of people moving either).

As such, the continuous (normal) probabilty distributions which underpin standard regression models don't hold. However, the discrtete probability distributions such as the Poisson distribution and the negative binomial distribution (of which the Poisson distribution is a special case - wikipedia it) do hold and so we can use these associations to model our flows.

At this point, it's probably worth you looking at what a Poisson disribution looks like compared to a normal distribution, if you are not familiar.

Here's a normal distribution:

``` r
#histogram with a count of 3000, a mean of 75 and a standard deviation of 5
qplot(rnorm(0:3000,mean=75,sd=5))
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-23-1.png)

Now here's a Poisson distribution with the same mean:

``` r
qplot(rpois(0:3000,lambda=75)) + stat_bin(binwidth = 1)
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-24-1.png)

Looks kind of similar doesn't it! The thing with the Poisson distribution is, when the mean (*λ* - lambda) changes, so does the distribution. As the mean gets smaller (and this is often the case with flow data where small flows are very likely - have a look at the 'Total' column in your cdata dataframe, lots of small numbers aren't there?) the distribution starts to look a lot more like a skewed or log-normal distrbution. They key thing is it's not - it's a Poisson distribution. Here's a similar frequency distribution with a small mean:

``` r
#what about a lambda of 0.5?
qplot(rpois(0:3000,0.5)) + stat_bin(binwidth = 1)
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-25-1.png)

As far as we're concerned, what this means is that if we are interested in all flows between all origins and destinations in our system, these flows will have a mean value of *λ*<sub>*i**j*</sub> and this will dictate the distribution. Here's what the distrbution of our flows looks like:

``` r
qplot(mdata$Flow) + geom_histogram()
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-26-1.png)

#### Mmmm, Poissony!

So, what does all of this mean for our spatial interaction model?

Well the main thing it means is that Equation 5, for most sorts of spatial interaction models where we are modelling flows of people or whole things, is not correct.

By logging both sides of the equation in Equation 5, we are trying to get a situation where our *T*<sub>*i**j*</sub> flows can be modelled by using the values of our other variables such as distance, by using a straight line a bit like this:

``` r
qplot(log(dist), log(Flow), data=mdatasub) + geom_smooth(method = lm)
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-27-1.png)

If you compare this graph with the graph above (the first scatter plot we drew in this practical exercise), it's exactly the same data, but clearly by logging both the total and distance, we can get a bit closer to being able to fit a model estimate using a straight line.

What the Poisson distribution means is that the *y* variable in our model is not logged as in the graph above, but it can still be modelled using something like the blue line - I hope that sort of makes sense. If not, don't worry, just take it from me that this is good news.

### The Poisson Regression Spatial Interaction Model

So, we can now re-specify Equation 5 as a Poisson Regression model. Instead of our independent variable being ln*T*<sub>*i**j*</sub> our dependent variable is now the mean of our Poisson distribution *λ*<sub>*i**j*</sub> and the model becomes:

1.  
    *λ*<sub>*i**j*</sub> = exp(*k* + *μ*ln*V*<sub>*i*</sub> + *α*ln*W*<sub>*j*</sub> − *β*ln*d*<sub>*i**j*</sub>)

What this model says is *λ*<sub>*i**j*</sub> (our independent variable - the estimate of *T*<sub>*i**j*</sub>) is *logarithmically linked * to (or modelled by) a linear combination of the logged independent variables in the model.

Now we have Equation 6 at our disposal, we can use a Poisson regression model to produce estimates of *k*, *μ*, *α* and *β* - or put another way, we can use the regression model to calibrate our parameters.

So, let's have a go at doing it!!

It's very straight forward to run a Poisson regression model in R using the `glm` (Generalised Linear Models) function. In practical terms, running a GLM model is no different to running a standard regression model using `lm`. If you want to find out more about glm, try the R help system `?glm` or google it to find the function details. If you delve far enough into the depths of what GLM does, you will find that the parameters are calibrated though an 'iteratively re-weighted least squares' algorithm. This algorithm does exaxtly the sort of job I described earlier, it fits lots of lines to the data, continually adjusting the parameters and then seeing if it can minimise the error between the observed and expected values useing some goodness-of-fit measure is maximised/minimised.

These sorts of algorithms have been around for years and are very well established so it makes sense to make use of them rather than trying to re-invent the wheel ourselves. So here we go...

``` r
#run the unconstrained model
uncosim <- glm(Flow ~ log(vi1_origpop)+log(wj3_destmedinc)+log(dist), na.action = na.exclude, family = poisson(link = "log"), data = mdatasub)
```

It's a simple as that - runs in a matter of milliseconds. You should be able to see how the `glm` R code corresponds to Equation 6.

`Total` = *T*<sub>*i**j*</sub> = *λ*<sub>*i**j*</sub>

`~` means 'is modelled by'

`log(vi1_origpop)` = *l**n**V*<sub>*i*</sub>

`log(wj2_destsal)` = *l**n**W*<sub>*j*</sub>

`log(dist)` = ln*d*<sub>*i**j*</sub>

`family = poisson(link = "log")` means that we are using a Poisson regression model (the link is always log with a Poisson model) where the left-hand side of the model equation is logarithmically linked to the variables on the right-hand side.

So what comes out of the other end?

Well, we can use the `summary()` function to have a look at the model parameters:

``` r
#run the unconstrained model
summary(uncosim) 
```

    ## 
    ## Call:
    ## glm(formula = Flow ~ log(vi1_origpop) + log(wj3_destmedinc) + 
    ##     log(dist), family = poisson(link = "log"), data = mdatasub, 
    ##     na.action = na.exclude)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -177.78   -54.49   -24.50     9.21   470.11  
    ## 
    ## Coefficients:
    ##                       Estimate Std. Error z value            Pr(>|z|)    
    ## (Intercept)          7.1953790  0.0248852  289.14 <0.0000000000000002 ***
    ## log(vi1_origpop)     0.5903363  0.0009232  639.42 <0.0000000000000002 ***
    ## log(wj3_destmedinc) -0.1671417  0.0033663  -49.65 <0.0000000000000002 ***
    ## log(dist)           -0.8119316  0.0010157 -799.41 <0.0000000000000002 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for poisson family taken to be 1)
    ## 
    ##     Null deviance: 2750417  on 209  degrees of freedom
    ## Residual deviance: 1503573  on 206  degrees of freedom
    ## AIC: 1505580
    ## 
    ## Number of Fisher Scoring iterations: 5

We can see from the summary that the Poisson regression has calibrated all 4 parameters for us and these appear under the 'estimate' column:

*k* (intercept) = 7.1953790

*μ* = 0.5903363

*α* = -0.1671417

and *β* = -0.8119316

We can also see from the other outputs that all variables are highly significant (\*\*\*), with the z-scores revealing that distance has the most influence on the model (as we might have expected from the scatter plots we produced earlier which showed that distance had by far the strongest correlation with migration flows).

These parameters are not too far away from our initial guesses of *μ* = 1, *α* = 1 and *β* = -2, but how do the estimates compare?

One way to calculate the estimates is to plug all of the parameters back into Equation 6 like this:

``` r
#first asign the parameter values from the model to the appropriate variables
k <- uncosim$coefficients[1]
mu <- uncosim$coefficients[2]
alpha <- uncosim$coefficients[3]
beta <- -uncosim$coefficients[4]

#now plug everything back into the Equation 6 model... (be careful with the positive and negative signing of the parameters as the beta parameter may not have been saved as negative so will need to force negative)
mdatasub$unconstrainedEst2 <- exp(k+(mu*log(mdatasub$vi1_origpop))+(alpha*log(mdatasub$wj3_destmedinc))-(beta*log(mdatasub$dist)))

#which is exactly the same as this...
mdatasub$unconstrainedEst2 <- (exp(k)*exp(mu*log(mdatasub$vi1_origpop))*exp(alpha*log(mdatasub$wj3_destmedinc))*exp(-beta*log(mdatasub$dist)))

#and of course, being R, there is an even easier way of doing this...
mdatasub$fitted <- fitted(uncosim)
```

``` r
#run the model and store all of the new flow estimates in a new column in the dataframe
mdatasub$unconstrainedEst2 <- round(mdatasub$unconstrainedEst2,0)
sum(mdatasub$unconstrainedEst2)
```

    ## [1] 1313517

``` r
#turn it into a little matrix and have a look at your handy work
mdatasubmat2 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "unconstrainedEst2", margins=c("Orig_code", "Dest_code"))
mdatasubmat2
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"30810","4":"20358","5":"19562","6":"17788","7":"11282","8":"13497","9":"10525","10":"5234","11":"5718","12":"13997","13":"14251","14":"5270","15":"7226","16":"39656","17":"215174"},{"1":"1RNSW","2":"20638","3":"0","4":"15339","5":"16316","6":"12198","7":"9789","8":"12439","9":"9661","10":"4114","11":"4616","12":"9181","13":"9507","14":"4200","15":"6002","16":"19373","17":"153373"},{"1":"2GMEL","2":"17285","3":"19443","4":"0","5":"69923","6":"10043","7":"9071","8":"19565","9":"11595","10":"5685","11":"5972","12":"21014","13":"24091","14":"4921","15":"6838","16":"24616","17":"250062"},{"1":"2RVIC","2":"9053","3":"11272","4":"38111","5":"0","6":"5413","7":"5035","8":"12044","9":"6686","10":"3070","11":"3264","12":"9444","13":"10515","14":"2680","15":"3771","16":"12432","17":"132790"},{"1":"3GBRI","2":"11364","3":"11634","4":"7556","5":"7473","6":"0","7":"9436","8":"6605","9":"6097","10":"3116","11":"3541","12":"5929","13":"5918","14":"3652","15":"4943","16":"8781","17":"96045"},{"1":"3RQLD","2":"6931","3":"8978","4":"6563","5":"6683","6":"9074","7":"0","8":"7227","9":"8378","10":"3783","11":"4719","12":"5087","13":"5111","14":"5517","15":"8428","16":"6351","17":"92830"},{"1":"4GADE","2":"5784","3":"7958","4":"9875","5":"11153","6":"4431","7":"5042","8":"0","9":"10176","10":"3464","11":"3787","12":"6102","13":"6449","14":"2847","15":"4206","16":"6519","17":"87793"},{"1":"4RSAU","2":"2278","3":"3122","4":"2956","5":"3127","6":"2066","7":"2952","8":"5140","9":"0","10":"1878","11":"2359","12":"2149","13":"2202","14":"1730","15":"2862","16":"2356","17":"37177"},{"1":"5GPER","2":"2986","3":"3504","4":"3820","5":"3784","6":"2782","7":"3512","8":"4611","9":"4950","10":"0","11":"8006","12":"3453","13":"3430","14":"3420","15":"4332","16":"3058","17":"55648"},{"1":"5RWAU","2":"1583","3":"1908","4":"1947","5":"1952","6":"1534","7":"2126","8":"2446","9":"3017","10":"3885","11":"0","12":"1676","13":"1673","14":"2380","15":"3215","16":"1599","17":"30941"},{"1":"6GHOB","2":"2125","3":"2081","4":"3758","5":"3099","6":"1409","7":"1257","8":"2162","9":"1507","10":"919","11":"919","12":"0","13":"13173","14":"753","15":"1004","16":"2535","17":"36701"},{"1":"6RTAS","2":"2653","3":"2642","4":"5282","5":"4230","6":"1724","7":"1549","8":"2801","9":"1894","10":"1119","11":"1125","12":"16150","13":"0","14":"918","15":"1232","16":"3249","17":"46568"},{"1":"7GDAR","2":"647","3":"769","4":"711","5":"710","6":"701","7":"1102","8":"815","9":"981","10":"736","11":"1055","12":"609","13":"605","14":"0","15":"2063","16":"627","17":"12131"},{"1":"7RNTE","2":"678","3":"841","4":"756","5":"765","6":"726","7":"1287","8":"921","9":"1241","10":"713","11":"1090","12":"620","13":"621","14":"1578","15":"0","16":"661","17":"12498"},{"1":"8ACTE","2":"9191","3":"6703","4":"6720","5":"6227","6":"3186","7":"2396","8":"3526","9":"2523","10":"1242","11":"1339","12":"3870","13":"4045","14":"1185","15":"1633","16":"0","17":"53786"},{"1":"(all)","2":"93196","3":"111665","4":"123752","5":"155004","6":"73075","7":"65836","8":"93799","9":"79231","10":"38958","11":"47510","12":"99281","13":"101591","14":"41051","15":"57755","16":"131813","17":"1313517"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

And the $1,000,000 question - has calibrating the parameters improved the model...?

``` r
CalcRSquared(mdatasub$Flow,mdatasub$unconstrainedEst2)
```

    ## [1] 0.3245418

``` r
CalcRMSE(mdatasub$Flow,mdatasub$unconstrainedEst2)
```

    ## [1] 10789.17

### Yes indeedy do!!

The *r*<sup>2</sup> has improved from 0.18 to 0.29 and the RMSE has reduced from 27535.2 to 11436.64 so by calibrating our parameters using the Poisson Regression Model, we have markedly improved our model fit.

But we can do even better. We have just been playing with the unconstrained model, by adding constraints into the model we can both improve our fit further AND start to do cool things like esimate transport trip distributions from know information about people leaving an area, or in different contexts estimate the amount of money a shop is going to make from the available money that people in the surrounding area have to spend, or guess the number of migrants travelling between specific countries where we only know how many people in total leave one country and arrive in another.

Section 2 - Constrained Models
------------------------------

If we return to [Alan Wilson's 1971 paper](http://journals.sagepub.com/doi/abs/10.1068/a030001), he introduces a full *family* of spatial interaction models of which the unconstrained model is just the start. And indeed since then, there have been all number of incremental advances and alternatives (such as [Stewart Fotheringham's Competing Destinations models](https://www.researchgate.net/publication/23537117_A_New_Set_of_Spatial-Interaction_Models_The_Theory_of_Competing_Destinations), [Pooler's production/attraction/cost relaxed models](http://journals.sagepub.com/doi/abs/10.1177/030913259401800102), [Stillwell's origin/destination parameter specific models](http://journals.sagepub.com/doi/pdf/10.1068/a101187) and [mine and Alan's own multi-level model](http://journals.sagepub.com/doi/pdf/10.1068/a45398) (to name just a few).

In this section we will explore the rest of Wilson's family - the Production (origin) Constrained Model; the Attraction (destination) constrained model; and the Doubly Constrained Model.

We will see how we can, again, use a Poisson regression model in R to calibrate these models and how, once calibrated, we can use the models in different contexts, such as Land Use Transportation Interaction (LUTI) modelling, retail modelling and migration modelling.

1. Production and Attraction Constrained Models
-----------------------------------------------

Wilson's real contribution to the field was in noticing that the unconstrained gravity model was sub-optimal as it did not make use of all of the available data in the system we are studying.

If we recall the estimates from our unconstrained model, none of the estimates summed to the observed in and out-flow totals:

``` r
mdatasubmat2
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"30810","4":"20358","5":"19562","6":"17788","7":"11282","8":"13497","9":"10525","10":"5234","11":"5718","12":"13997","13":"14251","14":"5270","15":"7226","16":"39656","17":"215174"},{"1":"1RNSW","2":"20638","3":"0","4":"15339","5":"16316","6":"12198","7":"9789","8":"12439","9":"9661","10":"4114","11":"4616","12":"9181","13":"9507","14":"4200","15":"6002","16":"19373","17":"153373"},{"1":"2GMEL","2":"17285","3":"19443","4":"0","5":"69923","6":"10043","7":"9071","8":"19565","9":"11595","10":"5685","11":"5972","12":"21014","13":"24091","14":"4921","15":"6838","16":"24616","17":"250062"},{"1":"2RVIC","2":"9053","3":"11272","4":"38111","5":"0","6":"5413","7":"5035","8":"12044","9":"6686","10":"3070","11":"3264","12":"9444","13":"10515","14":"2680","15":"3771","16":"12432","17":"132790"},{"1":"3GBRI","2":"11364","3":"11634","4":"7556","5":"7473","6":"0","7":"9436","8":"6605","9":"6097","10":"3116","11":"3541","12":"5929","13":"5918","14":"3652","15":"4943","16":"8781","17":"96045"},{"1":"3RQLD","2":"6931","3":"8978","4":"6563","5":"6683","6":"9074","7":"0","8":"7227","9":"8378","10":"3783","11":"4719","12":"5087","13":"5111","14":"5517","15":"8428","16":"6351","17":"92830"},{"1":"4GADE","2":"5784","3":"7958","4":"9875","5":"11153","6":"4431","7":"5042","8":"0","9":"10176","10":"3464","11":"3787","12":"6102","13":"6449","14":"2847","15":"4206","16":"6519","17":"87793"},{"1":"4RSAU","2":"2278","3":"3122","4":"2956","5":"3127","6":"2066","7":"2952","8":"5140","9":"0","10":"1878","11":"2359","12":"2149","13":"2202","14":"1730","15":"2862","16":"2356","17":"37177"},{"1":"5GPER","2":"2986","3":"3504","4":"3820","5":"3784","6":"2782","7":"3512","8":"4611","9":"4950","10":"0","11":"8006","12":"3453","13":"3430","14":"3420","15":"4332","16":"3058","17":"55648"},{"1":"5RWAU","2":"1583","3":"1908","4":"1947","5":"1952","6":"1534","7":"2126","8":"2446","9":"3017","10":"3885","11":"0","12":"1676","13":"1673","14":"2380","15":"3215","16":"1599","17":"30941"},{"1":"6GHOB","2":"2125","3":"2081","4":"3758","5":"3099","6":"1409","7":"1257","8":"2162","9":"1507","10":"919","11":"919","12":"0","13":"13173","14":"753","15":"1004","16":"2535","17":"36701"},{"1":"6RTAS","2":"2653","3":"2642","4":"5282","5":"4230","6":"1724","7":"1549","8":"2801","9":"1894","10":"1119","11":"1125","12":"16150","13":"0","14":"918","15":"1232","16":"3249","17":"46568"},{"1":"7GDAR","2":"647","3":"769","4":"711","5":"710","6":"701","7":"1102","8":"815","9":"981","10":"736","11":"1055","12":"609","13":"605","14":"0","15":"2063","16":"627","17":"12131"},{"1":"7RNTE","2":"678","3":"841","4":"756","5":"765","6":"726","7":"1287","8":"921","9":"1241","10":"713","11":"1090","12":"620","13":"621","14":"1578","15":"0","16":"661","17":"12498"},{"1":"8ACTE","2":"9191","3":"6703","4":"6720","5":"6227","6":"3186","7":"2396","8":"3526","9":"2523","10":"1242","11":"1339","12":"3870","13":"4045","14":"1185","15":"1633","16":"0","17":"53786"},{"1":"(all)","2":"93196","3":"111665","4":"123752","5":"155004","6":"73075","7":"65836","8":"93799","9":"79231","10":"38958","11":"47510","12":"99281","13":"101591","14":"41051","15":"57755","16":"131813","17":"1313517"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

Our estimates did sum to the grand total of flows, but this is because we were really fitting a 'total constrained' model which used *k* - our constant of proportionality - to ensure everything sort of added up (to within 1 commuter).

Where we have a full flow matrix to calibrate parameters, we can incorporate the row (origin) totals, column (destination) totals or both origina and destination totals to *constrain* our flow estimates to these known values.

As I outline in the accompanying paper, there are various reasons for wanting to do this, for example:

1.  If We are interested in flows of money into businesses or customers into shops, might have information on the amount of disposable income and shopping habits of the people living in different areas from loyalty card data. This is known information about our origins and so we could *constrain* our spatial interaction model to this known information - we can make the assumption that this level of disposable income remains the same. We can then use other information about the attractiveness of places these people might like to shop in (store size, variety / specialism of goods etc.), to estimate how much money a new store opening in the area might make, or if a new out-of-town shopping centre opens, how much it might affect the business of shops in the town centre. This is what is known in the literature as the 'retail model' and is perhaps the most common example of a **Production (orign) Constrained Spatial Interaction Model**

2.  We might be interested in understanding the impact of a large new employer in an area on the flows of traffic in the vicinity or on the demand for new worker accommodation nearby. A good example of where this might be the case is with large new infrastructure developments like new airports. For example, before the go-ahead for the new third runway at Heathrow was given, one option being considered was a new runway in the Thames Estuary. If a new airport was built here, what would be the potential impact on transport flows in the area and where might workers commute from? This sort of scenario could be tested with an **Attraction (destination) Constrained Spatial Interaction Model** where the number of new jobs in a destination is known (as well as jobs in the surrounding area) and the model could be used to estimate where the workers will be drawn from (and their likely travel-to-work patterns). This model is exactly the sort of model Land Use Transport Interaction (LUTI) model that was constructed by the Mechanicity Team in CASA - details [here](http://www.mechanicity.info/research/land-use-transport-interaction-modelling/#transport) if you are interested...

3.  We might be interested in understanding the changing patterns of commuting or migration over time. Data from the Census allows us to know an accurate snap-shot of migrating and commuting patterns every 10 years. In these full data matrices, we know both the numbers of commuters/migrants leaving origins and arriving at destinations as well as the interactions between them. If we constrain our model estimates to this known information at origin and destination, we can examine various things, including:

    1.  the ways that the patterns of commuting/migration differ from the model predictions - where we might get more migrant/commuter flows than we would expect
    2.  how the model parameters vary over time - for example how does distance / cost of travel affect flows over time? Are people prepared to travel further or less far than before?

2. Production-constrained Model
-------------------------------

1.  
    *T*<sub>*i**j*</sub> = *A*<sub>*i*</sub>*O*<sub>*i*</sub>*W*<sub>*j*</sub><sup>*α*</sup>*d*<sub>*i**j*</sub><sup>−</sup>*β*

where

1.  
    *O*<sub>*i*</sub> = ∑<sub>*j*</sub>*T*<sub>*i**j*</sub>

and

1.  
    $$ A\_i = \\frac{1}{\\sum\_j W\_j^\\alpha d\_{ij}^-\\beta}$$

In the production-constrained model, *O*<sub>*i*</sub> does not have a parameter as it is a known constraint. *A*<sub>*i*</sub> is known as a *balancing factor* and is a vector of values which relate to each origin, *i*, which do the equivalent job to *k* in the unconstrained/total constrained model but ensure that flow estimates from each origin sum to the know totals, *O*<sub>*i*</sub> rather than just the overall total.

Now at this point, we could calculate all of the *O*<sub>*i*</sub>s and the *A*<sub>*i*</sub>s by hand for our sample system and then set about guessing/estimating the parameter values for the rest of the model, but as you might have already suspected from last time, we can use R and `glm` to make it really easy and do all of that for us - woo hoo!

We set about re-specifying the Production-Constrained model as a Poisson regression model in exactly the same way as we did before. We need to take logs of the right-hand side of equation and assume that these are logarithmially linked to the Poisson distributed mean (*λ*<sub>*i**j*</sub>) of the *T*<sub>*i**j*</sub> variable. As such, Equation (1) becomes:

1.  
    *λ*<sub>*i**j*</sub> = *e**x**p*(*μ*<sub>*i*</sub> + *α*ln*W*<sub>*j*</sub> − *β*ln*d*<sub>*i**j*</sub>)

In Equation (4) *μ*<sub>*i*</sub> is the equivalent of the vector of balancing factors *A*<sub>*i*</sub>, but in regression / log-linear modelling terminology can also be described as either **dummy variables** or **fixed effects**. In practical terms, what this means is that in our regression model, *μ*<sub>*i*</sub> is modelled as a [categorical predictor](https://en.wikipedia.org/wiki/Categorical_variable) and therefore in the Poisson regression model, we don't use the numeric values of *O*<sub>*i*</sub>, we use a categorical identifier for the origin. In terms of the origin/destination migration matrix shown in Table 3, rather than the flow of 204,828 migrants leaving Sydney (row 1) being used as a predictor, simply the code ‘1GSYD’ is used as a dummy variable.

Before giving it a whirl, it's important to note in the code example below the use of '-1' after the distance variable (thanks to Hadrien Salat in CASA for bringing this to my attention). The -1 serves the purpose of removing the intercept that by default, GLM will insert into the model. As was mentioned earlier, the vector of origin parameters will replace the intercept in this model. It also serves the purpose

``` r
#run a production constrained SIM (the "-1" indicates no intercept in the regression model).
prodSim <- glm(Flow ~ Orig_code+log(wj3_destmedinc)+log(dist)-1, na.action = na.exclude, family = poisson(link = "log"), data = mdatasub)
#let's have a look at it's summary...
summary(prodSim)
```

    ## 
    ## Call:
    ## glm(formula = Flow ~ Orig_code + log(wj3_destmedinc) + log(dist) - 
    ##     1, family = poisson(link = "log"), data = mdatasub, na.action = na.exclude)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -225.71   -54.10   -15.94    20.45   374.27  
    ## 
    ## Coefficients:
    ##                      Estimate Std. Error z value            Pr(>|z|)    
    ## Orig_code1GSYD      19.541851   0.023767  822.22 <0.0000000000000002 ***
    ## Orig_code1RNSW      19.425497   0.023913  812.35 <0.0000000000000002 ***
    ## Orig_code2GMEL      18.875763   0.023243  812.12 <0.0000000000000002 ***
    ## Orig_code2RVIC      18.335242   0.022996  797.31 <0.0000000000000002 ***
    ## Orig_code3GBRI      19.856564   0.024063  825.20 <0.0000000000000002 ***
    ## Orig_code3RQLD      20.094898   0.024300  826.94 <0.0000000000000002 ***
    ## Orig_code4GADE      18.747938   0.023966  782.28 <0.0000000000000002 ***
    ## Orig_code4RSAU      18.324029   0.024407  750.75 <0.0000000000000002 ***
    ## Orig_code5GPER      20.010551   0.024631  812.43 <0.0000000000000002 ***
    ## Orig_code5RWAU      19.392751   0.024611  787.96 <0.0000000000000002 ***
    ## Orig_code6GHOB      16.802016   0.024282  691.97 <0.0000000000000002 ***
    ## Orig_code6RTAS      17.013981   0.023587  721.33 <0.0000000000000002 ***
    ## Orig_code7GDAR      18.607483   0.025012  743.93 <0.0000000000000002 ***
    ## Orig_code7RNTE      17.798856   0.025704  692.45 <0.0000000000000002 ***
    ## Orig_code8ACTE      17.796693   0.023895  744.79 <0.0000000000000002 ***
    ## log(wj3_destmedinc) -0.272640   0.003383  -80.59 <0.0000000000000002 ***
    ## log(dist)           -1.227679   0.001400 -876.71 <0.0000000000000002 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for poisson family taken to be 1)
    ## 
    ##     Null deviance: 23087017  on 210  degrees of freedom
    ## Residual deviance:  1207394  on 193  degrees of freedom
    ## AIC: 1209427
    ## 
    ## Number of Fisher Scoring iterations: 6

So, what do we have?

Well, there are the elements of the model output that should be familiar from the unconstrained model:

the *α* parameter related to the destination attractiveness: -0.272640

the *β* distance decay parameter: -1.227679

We can see from the standard outputs from the model that all of the explanatory variables are statistically significant (\*\*\*) and the z-scores indicate that the destination salary is having the most influence on the model, with distance following closely behind. And then we have a series of parameters which are the vector of *μ*<sub>*i*</sub> values associated with our origin constraints.

### 2.1 Model Estimates

Now at this point you will be wanting to know what affect the constraints have had on the estimates produced by the model, so let's plug the parameters back into Equation 4 and take a look...

Create some *O*<sub>*i*</sub> and *D*<sub>*j*</sub> columns and store the total in and out flow matrix margins in them. *Note, in the syntax below, I use the forward-pipe or %&gt;% operator. This is probably something a bit new and warrents a bit of explaining. If you'd like to know more about how pipes can be used in R, visit the [magrittr vignette page here](https://cran.r-project.org/web/packages/magrittr/vignettes/magrittr.html) - for now, just think of %&gt;% as a bit like saying "then..." in your code*

``` r
#create some Oi and Dj columns in the dataframe and store row and column totals in them:
#to create O_i, take mdatasub ...then... group by origcodenew ...then... summarise by calculating the sum of Total
O_i <- mdatasub %>% group_by(Orig_code) %>% summarise(O_i = sum(Flow))
mdatasub$O_i <- O_i$O_i[match(mdatasub$Orig_code,O_i$Orig_code)]
D_j <- mdatasub %>% group_by(Dest_code) %>% summarise(D_j = sum(Flow))
mdatasub$D_j <- D_j$D_j[match(mdatasub$Dest_code,D_j$Dest_code)]
```

Now fish the coefficients out of the prodsim glm object

``` r
#You can do this in a number of ways, for example this prints everything:
prodSim_out <- tidy(prodSim)
prodSim_out
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["term"],"name":[1],"type":["chr"],"align":["left"]},{"label":["estimate"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["std.error"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["statistic"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["p.value"],"name":[5],"type":["dbl"],"align":["right"]}],"data":[{"1":"Orig_code1GSYD","2":"19.5418513","3":"0.023767167","4":"822.2205","5":"0"},{"1":"Orig_code1RNSW","2":"19.4254971","3":"0.023912873","4":"812.3448","5":"0"},{"1":"Orig_code2GMEL","2":"18.8757634","3":"0.023242726","4":"812.1149","5":"0"},{"1":"Orig_code2RVIC","2":"18.3352425","3":"0.022996366","4":"797.3104","5":"0"},{"1":"Orig_code3GBRI","2":"19.8565639","3":"0.024062773","4":"825.1985","5":"0"},{"1":"Orig_code3RQLD","2":"20.0948982","3":"0.024300386","4":"826.9374","5":"0"},{"1":"Orig_code4GADE","2":"18.7479383","3":"0.023965685","4":"782.2826","5":"0"},{"1":"Orig_code4RSAU","2":"18.3240292","3":"0.024407456","4":"750.7554","5":"0"},{"1":"Orig_code5GPER","2":"20.0105511","3":"0.024630512","4":"812.4294","5":"0"},{"1":"Orig_code5RWAU","2":"19.3927512","3":"0.024611323","4":"787.9605","5":"0"},{"1":"Orig_code6GHOB","2":"16.8020157","3":"0.024281615","4":"691.9645","5":"0"},{"1":"Orig_code6RTAS","2":"17.0139814","3":"0.023586963","4":"721.3299","5":"0"},{"1":"Orig_code7GDAR","2":"18.6074834","3":"0.025012274","4":"743.9341","5":"0"},{"1":"Orig_code7RNTE","2":"17.7988564","3":"0.025704015","4":"692.4543","5":"0"},{"1":"Orig_code8ACTE","2":"17.7966931","3":"0.023894767","4":"744.7946","5":"0"},{"1":"log(wj3_destmedinc)","2":"-0.2726405","3":"0.003382993","4":"-80.5915","5":"0"},{"1":"log(dist)","2":"-1.2276790","3":"0.001400333","4":"-876.7054","5":"0"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

Or, more usefully, pull out the parameter values for *μ*<sub>*i*</sub> and store them back in the dataframe along with *O*<sub>*i*</sub> and *D*<sub>*j*</sub>

``` r
# or you can just pull out the coefficients and put them into an object
coefs <- as.data.frame(prodSim$coefficients)
#then once you have done this, you can join them back into the dataframe using a regular expression to match the bits of the identifier that you need - *note, this bit of code below took me about 2 hours to figure out!*
mdatasub$mu_i <- coefs$`prodSim$coefficients`[match(mdatasub$Orig_code,sub(".*Orig_code","", rownames(coefs)))]
#now, where we have missing values for our reference mu_i variable, fill those with 1s
head(mdatasub)
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Origin"],"name":[1],"type":["chr"],"align":["left"]},{"label":["Orig_code"],"name":[2],"type":["chr"],"align":["left"]},{"label":["Destination"],"name":[3],"type":["chr"],"align":["left"]},{"label":["Dest_code"],"name":[4],"type":["chr"],"align":["left"]},{"label":["Flow"],"name":[5],"type":["int"],"align":["right"]},{"label":["vi1_origpop"],"name":[6],"type":["int"],"align":["right"]},{"label":["wj1_destpop"],"name":[7],"type":["int"],"align":["right"]},{"label":["vi2_origunemp"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["wj2_destunemp"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["vi3_origmedinc"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["wj3_destmedinc"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["vi4_origpctrent"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["wj4_destpctrent"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["FlowNoIntra"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["offset"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["dist"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["unconstrainedEst1"],"name":[17],"type":["dbl"],"align":["right"]},{"label":["unconstrainedEst2"],"name":[18],"type":["dbl"],"align":["right"]},{"label":["fitted"],"name":[19],"type":["dbl"],"align":["right"]},{"label":["O_i"],"name":[20],"type":["int"],"align":["right"]},{"label":["D_j"],"name":[21],"type":["int"],"align":["right"]},{"label":["mu_i"],"name":[22],"type":["dbl"],"align":["right"]}],"data":[{"1":"Greater Sydney","2":"1GSYD","3":"Rest of NSW","4":"1RNSW","5":"91031","6":"4391673","7":"2512952","8":"5.74","9":"6.12","10":"780.64","11":"509.97","12":"31.77","13":"27.20","14":"91031","15":"1","16":"391.4379","17":"45500","18":"30810","19":"30809.92","20":"204822","21":"190047","22":"19.54185"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Melbourne","4":"2GMEL","5":"22601","6":"4391673","7":"3999981","8":"5.74","9":"5.47","10":"780.64","11":"407.95","12":"31.77","13":"27.34","14":"22601","15":"1","16":"682.7450","17":"11964","18":"20358","19":"20357.93","20":"204822","21":"145089","22":"19.54185"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Vic","4":"2RVIC","5":"4416","6":"4391673","7":"1345717","8":"5.74","9":"5.17","10":"780.64","11":"506.58","12":"31.77","13":"24.08","14":"4416","15":"1","16":"685.8484","17":"14723","18":"19562","19":"19562.14","20":"204822","21":"115683","22":"19.54185"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Brisbane","4":"3GBRI","5":"22888","6":"4391673","7":"2065998","8":"5.74","9":"5.86","10":"780.64","11":"767.08","12":"31.77","13":"33.19","14":"22888","15":"1","16":"707.9081","17":"20926","18":"17788","19":"17788.34","20":"204822","21":"159319","22":"19.54185"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Qld","4":"3RQLD","5":"27445","6":"4391673","7":"2253723","8":"5.74","9":"6.22","10":"780.64","11":"446.48","12":"31.77","13":"32.57","14":"27445","15":"1","16":"1386.4854","17":"3175","18":"11282","19":"11282.00","20":"204822","21":"210448","22":"19.54185"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Adelaide","4":"4GADE","5":"5817","6":"4391673","7":"1225235","8":"5.74","9":"5.78","10":"780.64","11":"445.53","12":"31.77","13":"28.27","14":"5817","15":"1","16":"1112.3157","17":"4923","18":"13497","19":"13496.85","20":"204822","21":"57139","22":"19.54185"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

OK, now we can save our parameter values into some variables...

``` r
#the numbers in the brackets refer to positions in the coefficient vector. Here, positions 1:15 relate to the mu_i values and 16 & 17 for alpha and beta. For different numbers of zones and other variables, these references will have to change. 
mu_i <- prodSim$coefficients[1:15]
alpha <- prodSim$coefficients[16]
beta <- prodSim$coefficients[17]
```

And we're ready to generate our estimates:

``` r
mdatasub$prodsimest1 <- exp((mdatasub$mu_i)+(alpha*log(mdatasub$wj3_destmedinc))+(beta*log(mdatasub$dist)))
```

Now of course we could also have done this the easy way, but again, I think it helps doing it the hard way, especially if we want to play with the parameters by hand or adjust any of the input values when running some what-if scenarios.

Here's the easy way again for those who can't remember:

``` r
mdatasub$prodsimFitted <- fitted(prodSim)

head(mdatasub)
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Origin"],"name":[1],"type":["chr"],"align":["left"]},{"label":["Orig_code"],"name":[2],"type":["chr"],"align":["left"]},{"label":["Destination"],"name":[3],"type":["chr"],"align":["left"]},{"label":["Dest_code"],"name":[4],"type":["chr"],"align":["left"]},{"label":["Flow"],"name":[5],"type":["int"],"align":["right"]},{"label":["vi1_origpop"],"name":[6],"type":["int"],"align":["right"]},{"label":["wj1_destpop"],"name":[7],"type":["int"],"align":["right"]},{"label":["vi2_origunemp"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["wj2_destunemp"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["vi3_origmedinc"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["wj3_destmedinc"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["vi4_origpctrent"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["wj4_destpctrent"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["FlowNoIntra"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["offset"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["dist"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["unconstrainedEst1"],"name":[17],"type":["dbl"],"align":["right"]},{"label":["unconstrainedEst2"],"name":[18],"type":["dbl"],"align":["right"]},{"label":["fitted"],"name":[19],"type":["dbl"],"align":["right"]},{"label":["O_i"],"name":[20],"type":["int"],"align":["right"]},{"label":["D_j"],"name":[21],"type":["int"],"align":["right"]},{"label":["mu_i"],"name":[22],"type":["dbl"],"align":["right"]},{"label":["prodsimest1"],"name":[23],"type":["dbl"],"align":["right"]},{"label":["prodsimFitted"],"name":[24],"type":["dbl"],"align":["right"]}],"data":[{"1":"Greater Sydney","2":"1GSYD","3":"Rest of NSW","4":"1RNSW","5":"91031","6":"4391673","7":"2512952","8":"5.74","9":"6.12","10":"780.64","11":"509.97","12":"31.77","13":"27.20","14":"91031","15":"1","16":"391.4379","17":"45500","18":"30810","19":"30809.92","20":"204822","21":"190047","22":"19.54185","23":"36793.753","24":"36793.753"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Melbourne","4":"2GMEL","5":"22601","6":"4391673","7":"3999981","8":"5.74","9":"5.47","10":"780.64","11":"407.95","12":"31.77","13":"27.34","14":"22601","15":"1","16":"682.7450","17":"11964","18":"20358","19":"20357.93","20":"204822","21":"145089","22":"19.54185","23":"19751.554","24":"19751.554"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Vic","4":"2RVIC","5":"4416","6":"4391673","7":"1345717","8":"5.74","9":"5.17","10":"780.64","11":"506.58","12":"31.77","13":"24.08","14":"4416","15":"1","16":"685.8484","17":"14723","18":"19562","19":"19562.14","20":"204822","21":"115683","22":"19.54185","23":"18515.858","24":"18515.858"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Brisbane","4":"3GBRI","5":"22888","6":"4391673","7":"2065998","8":"5.74","9":"5.86","10":"780.64","11":"767.08","12":"31.77","13":"33.19","14":"22888","15":"1","16":"707.9081","17":"20926","18":"17788","19":"17788.34","20":"204822","21":"159319","22":"19.54185","23":"15905.120","24":"15905.120"},{"1":"Greater Sydney","2":"1GSYD","3":"Rest of Qld","4":"3RQLD","5":"27445","6":"4391673","7":"2253723","8":"5.74","9":"6.22","10":"780.64","11":"446.48","12":"31.77","13":"32.57","14":"27445","15":"1","16":"1386.4854","17":"3175","18":"11282","19":"11282.00","20":"204822","21":"210448","22":"19.54185","23":"8076.279","24":"8076.279"},{"1":"Greater Sydney","2":"1GSYD","3":"Greater Adelaide","4":"4GADE","5":"5817","6":"4391673","7":"1225235","8":"5.74","9":"5.78","10":"780.64","11":"445.53","12":"31.77","13":"28.27","14":"5817","15":"1","16":"1112.3157","17":"4923","18":"13497","19":"13496.85","20":"204822","21":"57139","22":"19.54185","23":"10590.995","24":"10590.995"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

### 2.2 Assessing the model output

So what do the outputs from our Production Constrained Model look like? How has the goodness-of-fit improved and how can we start to use this a bit like a retail model and assess the likely impacts of changing destination attractiveness etc.?

#### 2.2.1 The flow matrix

``` r
#first round the estimates
mdatasub$prodsimFitted <- round(fitted(prodSim),0)
#now we can create pivot table to turn paired list into matrix (and compute the margins as well)
mdatasubmat3 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "prodsimFitted", margins=c("Orig_code", "Dest_code"))
mdatasubmat3
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"36794","4":"19752","5":"18516","6":"15905","7":"8076","8":"10591","9":"7248","10":"2504","11":"2860","12":"11192","13":"11454","14":"2519","15":"4105","16":"53308","17":"204824"},{"1":"1RNSW","2":"29163","3":"0","4":"18862","5":"20620","6":"13173","7":"9548","8":"13715","9":"9329","10":"2549","11":"3032","12":"8667","13":"9100","14":"2619","15":"4543","16":"26439","17":"171359"},{"1":"2GMEL","2":"8501","3":"10243","4":"0","5":"70950","6":"3742","7":"3243","8":"10367","9":"4685","10":"1584","11":"1705","12":"11552","13":"14147","14":"1268","15":"2109","16":"14474","17":"158570"},{"1":"2RVIC","2":"4924","3":"6918","4":"43838","5":"0","6":"2263","7":"2050","8":"7667","9":"3139","10":"961","11":"1053","12":"5309","13":"6221","14":"779","15":"1320","16":"7935","17":"94377"},{"1":"3GBRI","2":"21684","3":"22658","4":"11852","5":"11604","6":"0","7":"16555","8":"9653","9":"8526","10":"3069","11":"3722","12":"8200","13":"8144","14":"3886","15":"6207","16":"14647","17":"150407"},{"1":"3RQLD","2":"12057","3":"17984","4":"11248","5":"11511","6":"18128","7":"0","8":"12989","9":"16188","10":"4832","11":"6746","12":"7639","13":"7664","14":"8515","15":"16335","16":"10539","17":"162375"},{"1":"4GADE","2":"4109","3":"6714","4":"9345","5":"11186","6":"2747","7":"3376","8":"0","9":"9731","10":"1895","11":"2167","12":"4506","13":"4879","14":"1403","15":"2558","16":"4912","17":"69528"},{"1":"4RSAU","2":"1922","3":"3122","4":"2887","5":"3130","6":"1659","7":"2876","8":"6653","9":"0","10":"1438","11":"2028","12":"1780","13":"1840","14":"1264","15":"2736","16":"2017","17":"35352"},{"1":"5GPER","2":"3930","3":"5048","4":"5777","5":"5673","6":"3533","7":"5080","8":"7666","9":"8507","10":"0","11":"17470","12":"4952","13":"4882","14":"4812","15":"6954","16":"4064","17":"88348"},{"1":"5RWAU","2":"2445","3":"3269","4":"3387","5":"3386","6":"2333","7":"3862","8":"4775","9":"6535","10":"9514","11":"0","12":"2696","13":"2679","14":"4515","15":"7196","16":"2476","17":"59068"},{"1":"6GHOB","2":"619","3":"605","4":"1485","5":"1105","6":"333","7":"283","8":"643","9":"371","10":"175","11":"175","12":"0","13":"9840","14":"129","15":"201","16":"807","17":"16771"},{"1":"6RTAS","2":"827","3":"829","4":"2374","5":"1689","6":"431","7":"371","8":"908","9":"501","10":"225","11":"226","12":"12842","13":"0","14":"166","15":"261","16":"1121","17":"22771"},{"1":"7GDAR","2":"1030","3":"1350","4":"1204","5":"1198","6":"1165","7":"2331","8":"1478","9":"1948","10":"1253","11":"2159","12":"950","13":"937","14":"0","15":"6000","16":"981","17":"23984"},{"1":"7RNTE","2":"644","3":"899","4":"769","5":"779","6":"714","7":"1716","8":"1034","9":"1618","10":"695","11":"1321","12":"569","13":"568","14":"2303","15":"0","16":"618","17":"14247"},{"1":"8ACTE","2":"9622","3":"6021","4":"6070","5":"5386","6":"1939","7":"1274","8":"2285","9":"1373","10":"467","11":"523","12":"2631","13":"2802","14":"433","15":"712","16":"0","17":"41538"},{"1":"(all)","2":"101477","3":"122454","4":"138850","5":"166733","6":"68065","7":"60641","8":"90424","9":"79699","10":"31161","11":"45187","12":"83485","13":"85157","14":"34611","15":"61237","16":"144338","17":"1313519"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

And compared with the original observed data?

``` r
mdatasubmat
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["int"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["int"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["int"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["int"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["int"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["int"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["int"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["int"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["int"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["int"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["int"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["int"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["int"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["int"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["int"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["int"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"91031","4":"22601","5":"4416","6":"22888","7":"27445","8":"5817","9":"795","10":"10574","11":"2128","12":"1644","13":"1996","14":"1985","15":"832","16":"10670","17":"204822"},{"1":"1RNSW","2":"53562","3":"0","4":"12407","5":"13084","6":"21300","7":"35189","8":"3617","9":"1591","10":"4990","11":"3300","12":"970","13":"1882","14":"2248","15":"1439","16":"15779","17":"171358"},{"1":"2GMEL","2":"15560","3":"11095","4":"0","5":"70260","6":"13057","7":"16156","8":"6021","9":"1300","10":"10116","11":"2574","12":"2135","13":"2555","14":"2023","15":"996","16":"4724","17":"158572"},{"1":"2RVIC","2":"2527","3":"11967","4":"48004","5":"0","6":"4333","7":"10102","8":"3461","9":"2212","10":"3459","11":"2601","12":"672","13":"1424","14":"1547","15":"717","16":"1353","17":"94379"},{"1":"3GBRI","2":"12343","3":"16061","4":"13078","5":"4247","6":"0","7":"84649","8":"3052","9":"820","10":"4812","11":"1798","12":"1386","13":"2306","14":"1812","15":"909","16":"3134","17":"150407"},{"1":"3RQLD","2":"11634","3":"26701","4":"12284","5":"7573","6":"74410","7":"0","8":"3774","9":"1751","10":"6588","11":"4690","12":"1499","13":"3089","14":"3127","15":"2140","16":"3115","17":"162375"},{"1":"4GADE","2":"5421","3":"3518","4":"8810","5":"3186","6":"5447","7":"6173","8":"0","9":"25677","10":"3829","11":"1228","12":"602","13":"872","14":"1851","15":"921","16":"1993","17":"69528"},{"1":"4RSAU","2":"477","3":"1491","4":"1149","5":"2441","6":"820","7":"2633","8":"22015","9":"0","10":"1052","11":"1350","12":"142","13":"430","14":"681","15":"488","16":"183","17":"35352"},{"1":"5GPER","2":"6516","3":"4066","4":"11729","5":"2929","6":"5081","7":"7006","8":"2631","9":"867","10":"0","11":"41320","12":"1018","13":"1805","14":"1300","15":"413","16":"1666","17":"88347"},{"1":"5RWAU","2":"714","3":"2242","4":"1490","5":"1813","6":"1137","7":"4328","8":"807","9":"982","10":"42146","11":"0","12":"277","13":"1163","14":"1090","15":"623","16":"256","17":"59068"},{"1":"6GHOB","2":"1224","3":"1000","4":"3016","5":"622","6":"1307","7":"1804","8":"533","9":"106","10":"899","11":"363","12":"0","13":"5025","14":"190","15":"115","16":"565","17":"16769"},{"1":"6RTAS","2":"1024","3":"1866","4":"2639","5":"1636","6":"1543","7":"2883","8":"651","9":"342","10":"1210","11":"1032","12":"7215","13":"0","14":"268","15":"170","16":"292","17":"22771"},{"1":"7GDAR","2":"1238","3":"2178","4":"1953","5":"1480","6":"2769","7":"5108","8":"2105","9":"641","10":"2152","11":"954","12":"243","13":"335","14":"0","15":"1996","16":"832","17":"23984"},{"1":"7RNTE","2":"406","3":"1432","4":"700","5":"792","6":"896","7":"3018","8":"1296","9":"961","10":"699","11":"826","12":"96","13":"213","14":"2684","15":"0","16":"229","17":"14248"},{"1":"8ACTE","2":"6662","3":"15399","4":"5229","5":"1204","6":"4331","7":"3954","8":"1359","9":"134","10":"1514","11":"285","12":"369","13":"270","14":"617","15":"211","16":"0","17":"41538"},{"1":"(all)","2":"119308","3":"190047","4":"145089","5":"115683","6":"159319","7":"210448","8":"57139","9":"38179","10":"94040","11":"64449","12":"18268","13":"23365","14":"21423","15":"11970","16":"44791","17":"1313518"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

Here it is very easy to see the Origin Constraints working. The sum across all destinations for each origin in the estimated matrix is exactly the same as the same sum across the observed matrix - ∑<sub>*j*</sub>*T*<sub>*i**j*</sub> = ∑<sub>*j*</sub>*λ*<sub>*i**j*</sub> = *O*<sub>*i*</sub>, but clearly, the same is not true when you sum across all origins for each destination - ∑<sub>*i*</sub>*T*<sub>*i**j*</sub> ≠ ∑<sub>*i*</sub>*λ*<sub>*i**j*</sub> ≠ *D*<sub>*j*</sub>

#### 2.2.2 How do the fits compare with the unconstrained model from last time?

``` r
#use the functions from the last practical to calculate some goodness-of-fit statistics
CalcRSquared(mdatasub$Flow,mdatasub$prodsimFitted)
```

    ## [1] 0.4345011

``` r
CalcRMSE(mdatasub$Flow,mdatasub$prodsimFitted)
```

    ## [1] 9872.693

Clearly by constraining our model estimates to known origin totals, the fit of the model has improved quite considerably - from around 0.67 in the unconstrained model to around 0.82 in this model. The RMSE has also dropped quite noticably.

#### 2.2.3 A 'what if...' scenario

Now that we have calibrated our parameters and produced some estimates, we can start to play around with some what-if scenarios.

For example - What if the government invested lots of money in Tasmainia and average weekly salaries increased from 540.45 to 800.50 dollars a week? A far fetched scenario, but one that could make a good experiment.

First create create a new variable with these altered salaries:

``` r
mdatasub$wj3_destmedincScenario <- mdatasub$wj3_destmedinc
mdatasub$wj3_destmedincScenario <- ifelse(mdatasub$wj3_destmedincScenario == 540.45,800.50,mdatasub$wj3_destmedincScenario)
```

Now let's plug these new values into the model and see how this changes the flows in the system...

``` r
mdatasub$prodsimest2 <- exp((mdatasub$mu_i)+(alpha*log(mdatasub$wj3_destmedincScenario))+(beta*log(mdatasub$dist)))

mdatasub$prodsimest2 <- round(mdatasub$prodsimest2,0)
#now we can create pivot table to turn paired list into matrix (and compute the margins as well)
mdatasubmat4 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "prodsimest2", margins=c("Orig_code", "Dest_code"))
mdatasubmat4
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"36794","4":"19752","5":"18516","6":"15905","7":"8076","8":"10591","9":"7248","10":"2504","11":"2860","12":"11192","13":"10290","14":"2519","15":"4105","16":"53308","17":"203660"},{"1":"1RNSW","2":"29163","3":"0","4":"18862","5":"20620","6":"13173","7":"9548","8":"13715","9":"9329","10":"2549","11":"3032","12":"8667","13":"8176","14":"2619","15":"4543","16":"26439","17":"170435"},{"1":"2GMEL","2":"8501","3":"10243","4":"0","5":"70950","6":"3742","7":"3243","8":"10367","9":"4685","10":"1584","11":"1705","12":"11552","13":"12710","14":"1268","15":"2109","16":"14474","17":"157133"},{"1":"2RVIC","2":"4924","3":"6918","4":"43838","5":"0","6":"2263","7":"2050","8":"7667","9":"3139","10":"961","11":"1053","12":"5309","13":"5589","14":"779","15":"1320","16":"7935","17":"93745"},{"1":"3GBRI","2":"21684","3":"22658","4":"11852","5":"11604","6":"0","7":"16555","8":"9653","9":"8526","10":"3069","11":"3722","12":"8200","13":"7317","14":"3886","15":"6207","16":"14647","17":"149580"},{"1":"3RQLD","2":"12057","3":"17984","4":"11248","5":"11511","6":"18128","7":"0","8":"12989","9":"16188","10":"4832","11":"6746","12":"7639","13":"6885","14":"8515","15":"16335","16":"10539","17":"161596"},{"1":"4GADE","2":"4109","3":"6714","4":"9345","5":"11186","6":"2747","7":"3376","8":"0","9":"9731","10":"1895","11":"2167","12":"4506","13":"4384","14":"1403","15":"2558","16":"4912","17":"69033"},{"1":"4RSAU","2":"1922","3":"3122","4":"2887","5":"3130","6":"1659","7":"2876","8":"6653","9":"0","10":"1438","11":"2028","12":"1780","13":"1653","14":"1264","15":"2736","16":"2017","17":"35165"},{"1":"5GPER","2":"3930","3":"5048","4":"5777","5":"5673","6":"3533","7":"5080","8":"7666","9":"8507","10":"0","11":"17470","12":"4952","13":"4386","14":"4812","15":"6954","16":"4064","17":"87852"},{"1":"5RWAU","2":"2445","3":"3269","4":"3387","5":"3386","6":"2333","7":"3862","8":"4775","9":"6535","10":"9514","11":"0","12":"2696","13":"2407","14":"4515","15":"7196","16":"2476","17":"58796"},{"1":"6GHOB","2":"619","3":"605","4":"1485","5":"1105","6":"333","7":"283","8":"643","9":"371","10":"175","11":"175","12":"0","13":"8841","14":"129","15":"201","16":"807","17":"15772"},{"1":"6RTAS","2":"827","3":"829","4":"2374","5":"1689","6":"431","7":"371","8":"908","9":"501","10":"225","11":"226","12":"12842","13":"0","14":"166","15":"261","16":"1121","17":"22771"},{"1":"7GDAR","2":"1030","3":"1350","4":"1204","5":"1198","6":"1165","7":"2331","8":"1478","9":"1948","10":"1253","11":"2159","12":"950","13":"842","14":"0","15":"6000","16":"981","17":"23889"},{"1":"7RNTE","2":"644","3":"899","4":"769","5":"779","6":"714","7":"1716","8":"1034","9":"1618","10":"695","11":"1321","12":"569","13":"510","14":"2303","15":"0","16":"618","17":"14189"},{"1":"8ACTE","2":"9622","3":"6021","4":"6070","5":"5386","6":"1939","7":"1274","8":"2285","9":"1373","10":"467","11":"523","12":"2631","13":"2518","14":"433","15":"712","16":"0","17":"41254"},{"1":"(all)","2":"101477","3":"122454","4":"138850","5":"166733","6":"68065","7":"60641","8":"90424","9":"79699","10":"31161","11":"45187","12":"83485","13":"76508","14":"34611","15":"61237","16":"144338","17":"1304870"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

You will notice that by increasing the average salary in the rest of Tazmania, we've reduced the flows into this area (yes, I know, counterintuitively, but this is just an example), but have not reduced the flows into other zones - the original constraints are still working on the other zones. One way to get around this, now that we have calibrated our parameters, is to return to the multiplicative model in Equation 1 and run this model after calculating our own *A*<sub>*i*</sub> balancing factors.

``` r
#calculate some new wj^alpha and dij^beta values
wj2_alpha <- mdatasub$wj3_destmedinc^alpha
dist_beta <- mdatasub$dist^beta
#calculate the first stage of the Ai values
mdatasub$Ai1 <- wj2_alpha*dist_beta
#now do the sum over all js bit
A_i <- mdatasub %>% group_by(Orig_code) %>% summarise(A_i = sum(Ai1))
#now divide in to 1
A_i[,2] <- 1/A_i[,2]
#and write the A_i values back into the data frame
mdatasub$A_i <- A_i$A_i[match(mdatasub$Orig_code,A_i$Orig_code)]
```

So that is it for calculating your *A*<sub>*i*</sub> values. Now you have these, it's very simple to plug everything back into Equation 1 and generate some estimates...

``` r
#To check everything works, recreate the original estimates
mdatasub$prodsimest3 <- mdatasub$A_i*mdatasub$O_i*wj2_alpha*dist_beta
```

You should see that your new estimates are exactly the same as your first estimates. If they're not, then something has gone wrong. Now we have this though, we can keep messing around with some new estimates and keep the constraints. Remember, though, that you will need to recalculate *A*<sub>*i*</sub> each time you want to create a new set of estimates. Let's try with our new values for the destination salary in the rest of Tazmania:

``` r
#calculate some new wj^alpha and dij^beta values
wj3_alpha <- mdatasub$wj3_destmedincScenario^alpha
#calculate the first stage of the Ai values
mdatasub$Ai1 <- wj3_alpha*dist_beta
#now do the sum over all js bit
A_i <- mdatasub %>% group_by(Orig_code) %>% summarise(A_i = sum(Ai1))
#now divide in to 1
A_i[,2] <- 1/A_i[,2]
#and write the A_i values back into the data frame
mdatasub$A_i <- A_i$A_i[match(mdatasub$Orig_code,A_i$Orig_code)]
```

Now we have some new *A*<sub>*i*</sub>s, let's generate some new scenario flow estimates...

``` r
#To check everything works, recreate the original estimates
mdatasub$prodsimest4_scenario <- mdatasub$A_i*mdatasub$O_i*wj3_alpha*dist_beta
```

``` r
mdatasub$prodsimest4_scenario <- round(mdatasub$prodsimest4_scenario,0)
#now we can create pivot table to turn paired list into matrix (and compute the margins as well)
mdatasubmat5 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "prodsimest4_scenario", margins=c("Orig_code", "Dest_code"))
mdatasubmat5
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"37004","4":"19864","5":"18622","6":"15996","7":"8122","8":"10651","9":"7289","10":"2518","11":"2876","12":"11255","13":"10349","14":"2534","15":"4128","16":"53612","17":"204820"},{"1":"1RNSW","2":"29321","3":"0","4":"18964","5":"20731","6":"13244","7":"9600","8":"13790","9":"9380","10":"2563","11":"3048","12":"8713","13":"8220","14":"2633","15":"4567","16":"26583","17":"171357"},{"1":"2GMEL","2":"8579","3":"10336","4":"0","5":"71599","6":"3776","7":"3272","8":"10462","9":"4728","10":"1599","11":"1721","12":"11658","13":"12827","14":"1280","15":"2128","16":"14607","17":"158572"},{"1":"2RVIC","2":"4957","3":"6965","4":"44133","5":"0","6":"2279","7":"2064","8":"7719","9":"3160","10":"968","11":"1060","12":"5344","13":"5627","14":"784","15":"1329","16":"7989","17":"94378"},{"1":"3GBRI","2":"21804","3":"22783","4":"11918","5":"11668","6":"0","7":"16646","8":"9706","9":"8574","10":"3086","11":"3742","12":"8245","13":"7357","14":"3907","15":"6242","16":"14728","17":"150406"},{"1":"3RQLD","2":"12115","3":"18070","4":"11302","5":"11566","6":"18215","7":"0","8":"13052","9":"16266","10":"4856","11":"6778","12":"7676","13":"6918","14":"8556","15":"16414","16":"10590","17":"162374"},{"1":"4GADE","2":"4139","3":"6762","4":"9412","5":"11266","6":"2767","7":"3400","8":"0","9":"9801","10":"1909","11":"2183","12":"4538","13":"4415","14":"1413","15":"2577","16":"4947","17":"69529"},{"1":"4RSAU","2":"1933","3":"3138","4":"2903","5":"3147","6":"1668","7":"2891","8":"6688","9":"0","10":"1445","11":"2039","12":"1789","13":"1662","14":"1271","15":"2751","16":"2028","17":"35353"},{"1":"5GPER","2":"3952","3":"5077","4":"5810","5":"5705","6":"3553","7":"5109","8":"7709","9":"8555","10":"0","11":"17569","12":"4980","13":"4411","14":"4839","15":"6993","16":"4087","17":"88349"},{"1":"5RWAU","2":"2456","3":"3285","4":"3402","5":"3401","6":"2344","7":"3880","8":"4797","9":"6565","10":"9558","11":"0","12":"2708","13":"2418","14":"4536","15":"7229","16":"2487","17":"59066"},{"1":"6GHOB","2":"659","3":"643","4":"1579","5":"1175","6":"354","7":"301","8":"683","9":"395","10":"186","11":"186","12":"0","13":"9401","14":"137","15":"213","16":"858","17":"16770"},{"1":"6RTAS","2":"827","3":"829","4":"2374","5":"1689","6":"431","7":"371","8":"908","9":"501","10":"225","11":"226","12":"12842","13":"0","14":"166","15":"261","16":"1121","17":"22771"},{"1":"7GDAR","2":"1034","3":"1356","4":"1209","5":"1202","6":"1170","7":"2340","8":"1484","9":"1956","10":"1258","11":"2168","12":"954","13":"846","14":"0","15":"6024","16":"985","17":"23986"},{"1":"7RNTE","2":"647","3":"903","4":"772","5":"782","6":"717","7":"1723","8":"1039","9":"1625","10":"698","11":"1326","12":"571","13":"512","14":"2312","15":"0","16":"621","17":"14248"},{"1":"8ACTE","2":"9688","3":"6062","4":"6112","5":"5423","6":"1953","7":"1283","8":"2301","9":"1382","10":"471","11":"526","12":"2649","13":"2535","14":"436","15":"716","16":"0","17":"41537"},{"1":"(all)","2":"102111","3":"123213","4":"139754","5":"167976","6":"68467","7":"61002","8":"90989","9":"80177","10":"31340","11":"45448","12":"83922","13":"77498","14":"34804","15":"61572","16":"145243","17":"1313516"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

There are a number of things to note here. Firstly, flows into Tazmania have reduced, while flows into other regions have increased.

Secondly, yes, I know this was a bad example, but try with some of the other variables for yourself.

Thirdly, Our origin constraints are now holding again.

3. Attraction-Constrained Model
-------------------------------

The attraction constrained Model is virtually the same as the Production constrained model:

1.  
    *T*<sub>*i**j*</sub> = *D*<sub>*j*</sub>*B*<sub>*j*</sub>*V*<sub>*i*</sub><sup>*μ*</sup>*d*<sub>*i**j*</sub><sup>−</sup>*β*

where

1.  
    *D*<sub>*j*</sub> = ∑<sub>*i*</sub>*T*<sub>*i**j*</sub>

and

1.  
    $$ B\_j = \\frac{1}{\\sum\_i V\_i^\\mu d\_{ij}^-\\beta}$$

I won't dwell on the attraction constrained model, except to say that it can be run in R as you would expect:

1.  
    *λ*<sub>*i**j*</sub> = *e**x**p*(*μ*ln*V*<sub>*i*</sub> + *α*<sub>*i*</sub> − *β*ln*d*<sub>*i**j*</sub>)

or in R:

``` r
attrSim <- glm(Flow ~ Dest_code+log(vi1_origpop)+log(dist)-1, na.action = na.exclude, family = poisson(link = "log"), data = mdatasub)
summary(attrSim)
```

    ## 
    ## Call:
    ## glm(formula = Flow ~ Dest_code + log(vi1_origpop) + log(dist) - 
    ##     1, family = poisson(link = "log"), data = mdatasub, na.action = na.exclude)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -138.69   -33.38   -10.47    11.72   293.39  
    ## 
    ## Coefficients:
    ##                    Estimate Std. Error z value            Pr(>|z|)    
    ## Dest_code1GSYD    8.8262922  0.0176638   499.7 <0.0000000000000002 ***
    ## Dest_code1RNSW    9.1809447  0.0178316   514.9 <0.0000000000000002 ***
    ## Dest_code2GMEL    8.6716196  0.0170155   509.6 <0.0000000000000002 ***
    ## Dest_code2RVIC    8.0861927  0.0173840   465.1 <0.0000000000000002 ***
    ## Dest_code3GBRI    9.5462594  0.0183631   519.9 <0.0000000000000002 ***
    ## Dest_code3RQLD   10.1295722  0.0184672   548.5 <0.0000000000000002 ***
    ## Dest_code4GADE    8.3051406  0.0184018   451.3 <0.0000000000000002 ***
    ## Dest_code4RSAU    8.1438651  0.0188772   431.4 <0.0000000000000002 ***
    ## Dest_code5GPER    9.9664486  0.0190008   524.5 <0.0000000000000002 ***
    ## Dest_code5RWAU    9.3061908  0.0190006   489.8 <0.0000000000000002 ***
    ## Dest_code6GHOB    6.9737562  0.0186288   374.4 <0.0000000000000002 ***
    ## Dest_code6RTAS    7.1546249  0.0183673   389.5 <0.0000000000000002 ***
    ## Dest_code7GDAR    8.3972440  0.0199735   420.4 <0.0000000000000002 ***
    ## Dest_code7RNTE    7.4521232  0.0206128   361.5 <0.0000000000000002 ***
    ## Dest_code8ACTE    7.3585270  0.0181823   404.7 <0.0000000000000002 ***
    ## log(vi1_origpop)  0.5828662  0.0009556   610.0 <0.0000000000000002 ***
    ## log(dist)        -1.1820013  0.0015267  -774.2 <0.0000000000000002 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for poisson family taken to be 1)
    ## 
    ##     Null deviance: 23087017  on 210  degrees of freedom
    ## Residual deviance:   665984  on 193  degrees of freedom
    ## AIC: 668017
    ## 
    ## Number of Fisher Scoring iterations: 5

we can examine how the constraints hold for destinations this time:

``` r
#first round the estimates
mdatasub$attrsimFitted <- round(fitted(attrSim),0)
#now we can create pivot table to turn paired list into matrix (and compute the margins as well)
mdatasubmat6 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "attrsimFitted", margins=c("Orig_code", "Dest_code"))
mdatasubmat6
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"62297","4":"19396","5":"10743","6":"44563","7":"36077","8":"7551","9":"4651","10":"11295","11":"6699","12":"2100","13":"2711","14":"2500","15":"1347","16":"16612","17":"228542"},{"1":"1RNSW","2":"31560","3":"0","4":"14989","5":"9626","6":"30026","7":"34242","8":"7824","9":"4791","10":"9285","11":"5724","12":"1326","13":"1755","14":"2097","15":"1200","16":"6832","17":"161277"},{"1":"2GMEL","2":"21440","3":"32707","4":"0","5":"70421","6":"19896","7":"26950","8":"13303","9":"5496","10":"13073","11":"7323","12":"3893","13":"5974","14":"2322","15":"1276","16":"8514","17":"232588"},{"1":"2RVIC","2":"11302","3":"19990","4":"67018","5":"0","6":"10936","7":"15458","8":"8873","9":"3332","10":"7206","11":"4106","12":"1642","13":"2415","14":"1296","15":"725","16":"4257","17":"158556"},{"1":"3GBRI","2":"13977","3":"18589","4":"5645","5":"3260","6":"0","7":"34266","8":"3286","9":"2588","10":"6540","11":"4108","12":"741","13":"929","14":"1806","15":"955","16":"2279","17":"98969"},{"1":"3RQLD","2":"6643","3":"12446","4":"4489","5":"2705","6":"20116","7":"0","8":"3658","9":"4013","10":"8466","11":"6091","12":"579","13":"733","14":"3215","15":"2027","16":"1388","17":"76569"},{"1":"4GADE","2":"6042","3":"12358","4":"9630","5":"6749","6":"8385","7":"15896","8":"0","9":"6304","10":"8815","11":"5234","12":"892","13":"1217","14":"1452","15":"872","16":"1707","17":"85553"},{"1":"4RSAU","2":"2170","3":"4413","4":"2320","5":"1478","6":"3851","7":"10169","8":"3676","9":"0","10":"5043","11":"3664","12":"272","13":"355","14":"981","15":"694","16":"541","17":"39627"},{"1":"5GPER","2":"2098","3":"3404","4":"2196","5":"1272","6":"3872","7":"8540","8":"2046","9":"2007","10":"0","11":"14148","12":"354","13":"441","14":"1724","15":"828","16":"515","17":"43445"},{"1":"5RWAU","2":"1172","3":"1977","4":"1159","5":"683","6":"2291","7":"5786","8":"1144","9":"1374","10":"13327","11":"0","12":"174","13":"218","14":"1431","15":"755","16":"282","17":"31773"},{"1":"6GHOB","2":"2286","3":"2850","4":"3834","5":"1700","6":"2571","7":"3421","8":"1214","9":"635","10":"2076","11":"1083","12":"0","13":"5592","14":"341","15":"176","16":"701","17":"28480"},{"1":"6RTAS","2":"2914","3":"3724","4":"5810","5":"2468","6":"3184","7":"4278","8":"1635","9":"818","10":"2554","11":"1342","12":"5522","13":"0","14":"419","15":"219","16":"929","17":"35816"},{"1":"7GDAR","2":"472","3":"782","4":"397","5":"233","6":"1088","7":"3298","8":"343","9":"397","10":"1754","11":"1545","12":"59","13":"74","14":"0","15":"587","16":"107","17":"11136"},{"1":"7RNTE","2":"550","3":"967","4":"471","5":"281","6":"1243","7":"4494","8":"445","9":"608","10":"1819","11":"1761","12":"66","13":"83","14":"1269","15":"0","16":"126","17":"14183"},{"1":"8ACTE","2":"16682","3":"13543","4":"7735","5":"4064","6":"7297","7":"7572","8":"2142","9":"1164","10":"2787","11":"1620","12":"647","13":"868","14":"570","15":"310","16":"0","17":"67001"},{"1":"(all)","2":"119308","3":"190047","4":"145089","5":"115683","6":"159319","7":"210447","8":"57140","9":"38178","10":"94040","11":"64448","12":"18267","13":"23365","14":"21423","15":"11971","16":"44790","17":"1313515"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

compared to...

``` r
mdatasubmat
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["int"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["int"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["int"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["int"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["int"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["int"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["int"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["int"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["int"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["int"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["int"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["int"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["int"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["int"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["int"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["int"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"91031","4":"22601","5":"4416","6":"22888","7":"27445","8":"5817","9":"795","10":"10574","11":"2128","12":"1644","13":"1996","14":"1985","15":"832","16":"10670","17":"204822"},{"1":"1RNSW","2":"53562","3":"0","4":"12407","5":"13084","6":"21300","7":"35189","8":"3617","9":"1591","10":"4990","11":"3300","12":"970","13":"1882","14":"2248","15":"1439","16":"15779","17":"171358"},{"1":"2GMEL","2":"15560","3":"11095","4":"0","5":"70260","6":"13057","7":"16156","8":"6021","9":"1300","10":"10116","11":"2574","12":"2135","13":"2555","14":"2023","15":"996","16":"4724","17":"158572"},{"1":"2RVIC","2":"2527","3":"11967","4":"48004","5":"0","6":"4333","7":"10102","8":"3461","9":"2212","10":"3459","11":"2601","12":"672","13":"1424","14":"1547","15":"717","16":"1353","17":"94379"},{"1":"3GBRI","2":"12343","3":"16061","4":"13078","5":"4247","6":"0","7":"84649","8":"3052","9":"820","10":"4812","11":"1798","12":"1386","13":"2306","14":"1812","15":"909","16":"3134","17":"150407"},{"1":"3RQLD","2":"11634","3":"26701","4":"12284","5":"7573","6":"74410","7":"0","8":"3774","9":"1751","10":"6588","11":"4690","12":"1499","13":"3089","14":"3127","15":"2140","16":"3115","17":"162375"},{"1":"4GADE","2":"5421","3":"3518","4":"8810","5":"3186","6":"5447","7":"6173","8":"0","9":"25677","10":"3829","11":"1228","12":"602","13":"872","14":"1851","15":"921","16":"1993","17":"69528"},{"1":"4RSAU","2":"477","3":"1491","4":"1149","5":"2441","6":"820","7":"2633","8":"22015","9":"0","10":"1052","11":"1350","12":"142","13":"430","14":"681","15":"488","16":"183","17":"35352"},{"1":"5GPER","2":"6516","3":"4066","4":"11729","5":"2929","6":"5081","7":"7006","8":"2631","9":"867","10":"0","11":"41320","12":"1018","13":"1805","14":"1300","15":"413","16":"1666","17":"88347"},{"1":"5RWAU","2":"714","3":"2242","4":"1490","5":"1813","6":"1137","7":"4328","8":"807","9":"982","10":"42146","11":"0","12":"277","13":"1163","14":"1090","15":"623","16":"256","17":"59068"},{"1":"6GHOB","2":"1224","3":"1000","4":"3016","5":"622","6":"1307","7":"1804","8":"533","9":"106","10":"899","11":"363","12":"0","13":"5025","14":"190","15":"115","16":"565","17":"16769"},{"1":"6RTAS","2":"1024","3":"1866","4":"2639","5":"1636","6":"1543","7":"2883","8":"651","9":"342","10":"1210","11":"1032","12":"7215","13":"0","14":"268","15":"170","16":"292","17":"22771"},{"1":"7GDAR","2":"1238","3":"2178","4":"1953","5":"1480","6":"2769","7":"5108","8":"2105","9":"641","10":"2152","11":"954","12":"243","13":"335","14":"0","15":"1996","16":"832","17":"23984"},{"1":"7RNTE","2":"406","3":"1432","4":"700","5":"792","6":"896","7":"3018","8":"1296","9":"961","10":"699","11":"826","12":"96","13":"213","14":"2684","15":"0","16":"229","17":"14248"},{"1":"8ACTE","2":"6662","3":"15399","4":"5229","5":"1204","6":"4331","7":"3954","8":"1359","9":"134","10":"1514","11":"285","12":"369","13":"270","14":"617","15":"211","16":"0","17":"41538"},{"1":"(all)","2":"119308","3":"190047","4":"145089","5":"115683","6":"159319","7":"210448","8":"57139","9":"38179","10":"94040","11":"64449","12":"18268","13":"23365","14":"21423","15":"11970","16":"44791","17":"1313518"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

and we can test the goodness-of-fit in exactly the same way as before:

``` r
#use the functions from the last practical to calculate some goodness-of-fit statistics
CalcRSquared(mdatasub$Flow,mdatasub$attrsimFitted)
```

    ## [1] 0.6550357

``` r
CalcRMSE(mdatasub$Flow,mdatasub$attrsimFitted)
```

    ## [1] 7714.627

OK, that's where I'll leave singly constrained models for now. There are, of course, plenty of things you could try out. For example:

1.  You could try mapping the coefficients or the residual values from the model to see if there is any patterning in either the over or under prediction of flows.

2.  You could try running your own version of a LUTI model by first calibrating the model parameters and plugging these into a multiplicative version of the model, adjusting the destination constraints to see which origins are likely to generate more trips.

4. Doubly Constrained Model
---------------------------

Now, the model in the family you have all been waiting for - the big boss, the daddy, the **doubly constrained model!**

Let's begin with the formula:

1.  
    *T*<sub>*i**j*</sub> = *A*<sub>*i*</sub>*O*<sub>*i*</sub>*B*<sub>*j*</sub>*D*<sub>*j*</sub>*d*<sub>*i**j*</sub><sup>−</sup>*β*

where

1.  
    *O*<sub>*i*</sub> = ∑<sub>*j*</sub>*T*<sub>*i**j*</sub>

2.  
    *D*<sub>*j*</sub> = ∑<sub>*i*</sub>*T*<sub>*i**j*</sub>

and

1.  
    $$A\_i = \\frac{1}{\\sum\_j B\_j D\_j d\_{ij}^-\\beta}$$

2.  
    $$B\_j = \\frac{1}{\\sum\_i A\_i O\_i d\_{ij}^-\\beta}$$

Now, the astute will have noticed that the calculation of *A*<sub>*i*</sub> relies on knowing *B*<sub>*j*</sub> and the calculation of *B*<sub>*j*</sub> relies on knowing *A*<sub>*i*</sub>. A conundrum!! If I don't know *A*<sub>*i*</sub> how can I calcuate *B*<sub>*j*</sub> and then in turn *A*<sub>*i*</sub> and then *B*<sub>*j*</sub> *ad infinitum*???!!

Well, I wrestled with that for a while until I came across [this paper by Martyn Senior](http://journals.sagepub.com/doi/abs/10.1177/030913257900300218) where he sketches out a very useful algorithm for iteratively arriving at values for *A*<sub>*i*</sub> and *B*<sub>*j*</sub> by setting each to equal 1 initially and then continuing to calculate each in turn until the difference between each value is small enough not to matter.

We will return to this later, but for now, we will once again use the awesome power of R to deal with all of this difficulty for us!

We can run the doubly constrained model in exactly the same way as we ran the singly constrained models:

1.  
    *λ*<sub>*i**j*</sub> = *e**x**p*(*μ*<sub>*i*</sub> + *α*<sub>*i*</sub> − *β*ln*d*<sub>*i**j*</sub>)

The code below has changed a litte from the singly constrained models I have removed the '-1' which means that an intercept will appear in the model again. This is not because I want an intercept as it makes the origin and destination coefficients harder to interpret - reference categories zones will appear and the coefficients will need to be compared with the intercept - rather the '-1' cheat for removing the intercept only works with one factor level - here we have two (origins and destinations). For full details and an explanation for alternative ways for dealing with this, please visit here - <https://stats.stackexchange.com/questions/215779/removing-intercept-from-glm-for-multiple-factorial-predictors-only-works-for-fir> - for ease, here we will just continue with the intercept.

``` r
#run a production constrained SIM
doubSim <- glm(Flow ~ Orig_code+Dest_code+log(dist), na.action = na.exclude, family = poisson(link = "log"), data = mdatasub)
#let's have a look at it's summary...
summary(doubSim)
```

    ## 
    ## Call:
    ## glm(formula = Flow ~ Orig_code + Dest_code + log(dist), family = poisson(link = "log"), 
    ##     data = mdatasub, na.action = na.exclude)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -93.018  -26.703    0.021   19.046  184.179  
    ## 
    ## Coefficients:
    ##                 Estimate Std. Error  z value            Pr(>|z|)    
    ## (Intercept)    20.208178   0.011308 1786.999 <0.0000000000000002 ***
    ## Orig_code1RNSW -0.122417   0.003463  -35.353 <0.0000000000000002 ***
    ## Orig_code2GMEL -0.455872   0.003741 -121.852 <0.0000000000000002 ***
    ## Orig_code2RVIC -1.434386   0.004511 -317.969 <0.0000000000000002 ***
    ## Orig_code3GBRI  0.241303   0.003597   67.091 <0.0000000000000002 ***
    ## Orig_code3RQLD  0.772753   0.003599  214.700 <0.0000000000000002 ***
    ## Orig_code4GADE -0.674261   0.004527 -148.936 <0.0000000000000002 ***
    ## Orig_code4RSAU -1.248974   0.005889 -212.091 <0.0000000000000002 ***
    ## Orig_code5GPER  0.742687   0.004668  159.118 <0.0000000000000002 ***
    ## Orig_code5RWAU -0.317806   0.005131  -61.943 <0.0000000000000002 ***
    ## Orig_code6GHOB -2.270736   0.008576 -264.767 <0.0000000000000002 ***
    ## Orig_code6RTAS -1.988784   0.007477 -265.981 <0.0000000000000002 ***
    ## Orig_code7GDAR -0.797620   0.007089 -112.513 <0.0000000000000002 ***
    ## Orig_code7RNTE -1.893522   0.008806 -215.022 <0.0000000000000002 ***
    ## Orig_code8ACTE -1.921309   0.005511 -348.631 <0.0000000000000002 ***
    ## Dest_code1RNSW  0.389478   0.003899   99.894 <0.0000000000000002 ***
    ## Dest_code2GMEL -0.007616   0.004244   -1.794              0.0727 .  
    ## Dest_code2RVIC -0.781258   0.004654 -167.854 <0.0000000000000002 ***
    ## Dest_code3GBRI  0.795909   0.004037  197.178 <0.0000000000000002 ***
    ## Dest_code3RQLD  1.516186   0.003918  386.955 <0.0000000000000002 ***
    ## Dest_code4GADE -0.331189   0.005232  -63.304 <0.0000000000000002 ***
    ## Dest_code4RSAU -0.627202   0.006032 -103.980 <0.0000000000000002 ***
    ## Dest_code5GPER  1.390114   0.005022  276.811 <0.0000000000000002 ***
    ## Dest_code5RWAU  0.367314   0.005362   68.509 <0.0000000000000002 ***
    ## Dest_code6GHOB -1.685934   0.008478 -198.859 <0.0000000000000002 ***
    ## Dest_code6RTAS -1.454819   0.007612 -191.112 <0.0000000000000002 ***
    ## Dest_code7GDAR -0.308516   0.007716  -39.986 <0.0000000000000002 ***
    ## Dest_code7RNTE -1.462020   0.009743 -150.060 <0.0000000000000002 ***
    ## Dest_code8ACTE -1.506283   0.005709 -263.866 <0.0000000000000002 ***
    ## log(dist)      -1.589102   0.001685 -942.842 <0.0000000000000002 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for poisson family taken to be 1)
    ## 
    ##     Null deviance: 2750417  on 209  degrees of freedom
    ## Residual deviance:  335759  on 180  degrees of freedom
    ## AIC: 337818
    ## 
    ## Number of Fisher Scoring iterations: 6

And the various flows and goodness-of-fit statistics?

``` r
#then round the estimates
mdatasub$doubsimFitted <- round(fitted(doubSim),0)
#now we can create pivot table to turn paired list into matrix (and compute the margins as well)
mdatasubmat7 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "doubsimFitted", margins=c("Orig_code", "Dest_code"))
mdatasubmat7
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"66903","4":"18581","5":"8510","6":"39179","7":"27666","8":"6190","9":"2981","10":"6373","11":"2758","12":"1712","13":"2384","14":"1266","15":"620","16":"19698","17":"204821"},{"1":"1RNSW","2":"40099","3":"0","4":"18006","5":"10062","6":"31574","7":"35342","8":"8897","9":"4252","10":"6711","11":"3060","12":"1265","13":"1821","14":"1369","15":"727","16":"8174","17":"171359"},{"1":"2GMEL","2":"11868","3":"19189","4":"0","5":"72706","6":"9037","7":"12748","8":"9040","9":"2545","10":"5291","11":"2121","12":"2677","13":"4705","14":"782","15":"393","16":"5470","17":"158572"},{"1":"2RVIC","2":"4429","3":"8737","4":"59237","5":"0","6":"3567","7":"5329","8":"4629","9":"1146","10":"2097","11":"860","12":"740","13":"1229","14":"315","15":"162","16":"1901","17":"94378"},{"1":"3GBRI","2":"22501","3":"30254","4":"8125","5":"3937","6":"0","7":"59334","8":"4650","9":"3116","10":"7027","11":"3285","12":"969","13":"1299","14":"1879","15":"897","16":"3134","17":"150407"},{"1":"3RQLD","2":"13155","3":"28037","4":"9490","5":"4869","6":"49124","7":"0","8":"8534","9":"8930","10":"15802","11":"8866","12":"1105","13":"1500","14":"6483","15":"3921","16":"2558","17":"162374"},{"1":"4GADE","2":"4392","3":"10534","4":"10043","5":"6311","6":"5745","7":"12736","8":"0","9":"6216","10":"6328","11":"2743","12":"751","13":"1125","14":"845","15":"479","16":"1281","17":"69529"},{"1":"4RSAU","2":"1601","3":"3809","4":"2139","5":"1183","6":"2914","7":"10085","8":"4704","9":"0","10":"4312","11":"2452","12":"220","13":"310","14":"720","15":"509","16":"394","17":"35352"},{"1":"5GPER","2":"3336","3":"5860","4":"4336","5":"2109","6":"6404","7":"17395","8":"4668","9":"4203","10":"0","11":"32886","12":"682","13":"906","14":"3352","15":"1405","16":"806","17":"88348"},{"1":"5RWAU","2":"1390","3":"2573","4":"1673","5":"833","6":"2883","7":"9398","8":"1948","9":"2302","10":"31670","11":"0","12":"239","13":"321","14":"2379","15":"1131","16":"327","17":"59067"},{"1":"6GHOB","2":"954","3":"1176","4":"2336","5":"793","6":"940","7":"1295","8":"589","9":"228","10":"727","11":"265","12":"0","13":"7014","14":"96","15":"45","16":"311","17":"16769"},{"1":"6RTAS","2":"1398","3":"1781","4":"4318","5":"1384","6":"1326","7":"1850","8":"929","9":"339","10":"1015","11":"373","12":"7380","13":"0","14":"135","15":"63","16":"480","17":"22771"},{"1":"7GDAR","2":"776","3":"1401","4":"751","5":"371","6":"2007","7":"8361","8":"730","9":"822","10":"3927","11":"2894","12":"106","13":"141","14":"0","15":"1529","16":"169","17":"23985"},{"1":"7RNTE","2":"403","3":"788","4":"400","5":"202","6":"1014","7":"5356","8":"438","9":"615","10":"1743","11":"1458","12":"52","13":"70","14":"1620","15":"0","16":"88","17":"14247"},{"1":"8ACTE","2":"13007","3":"9006","4":"5655","5":"2412","6":"3603","7":"3552","8":"1192","9":"485","10":"1017","11":"428","12":"368","13":"540","14":"182","15":"90","16":"0","17":"41537"},{"1":"(all)","2":"119309","3":"190048","4":"145090","5":"115682","6":"159317","7":"210447","8":"57138","9":"38180","10":"94040","11":"64449","12":"18266","13":"23365","14":"21423","15":"11971","16":"44791","17":"1313516"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

compared to...

``` r
mdatasubmat
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["int"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["int"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["int"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["int"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["int"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["int"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["int"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["int"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["int"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["int"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["int"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["int"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["int"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["int"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["int"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["int"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"91031","4":"22601","5":"4416","6":"22888","7":"27445","8":"5817","9":"795","10":"10574","11":"2128","12":"1644","13":"1996","14":"1985","15":"832","16":"10670","17":"204822"},{"1":"1RNSW","2":"53562","3":"0","4":"12407","5":"13084","6":"21300","7":"35189","8":"3617","9":"1591","10":"4990","11":"3300","12":"970","13":"1882","14":"2248","15":"1439","16":"15779","17":"171358"},{"1":"2GMEL","2":"15560","3":"11095","4":"0","5":"70260","6":"13057","7":"16156","8":"6021","9":"1300","10":"10116","11":"2574","12":"2135","13":"2555","14":"2023","15":"996","16":"4724","17":"158572"},{"1":"2RVIC","2":"2527","3":"11967","4":"48004","5":"0","6":"4333","7":"10102","8":"3461","9":"2212","10":"3459","11":"2601","12":"672","13":"1424","14":"1547","15":"717","16":"1353","17":"94379"},{"1":"3GBRI","2":"12343","3":"16061","4":"13078","5":"4247","6":"0","7":"84649","8":"3052","9":"820","10":"4812","11":"1798","12":"1386","13":"2306","14":"1812","15":"909","16":"3134","17":"150407"},{"1":"3RQLD","2":"11634","3":"26701","4":"12284","5":"7573","6":"74410","7":"0","8":"3774","9":"1751","10":"6588","11":"4690","12":"1499","13":"3089","14":"3127","15":"2140","16":"3115","17":"162375"},{"1":"4GADE","2":"5421","3":"3518","4":"8810","5":"3186","6":"5447","7":"6173","8":"0","9":"25677","10":"3829","11":"1228","12":"602","13":"872","14":"1851","15":"921","16":"1993","17":"69528"},{"1":"4RSAU","2":"477","3":"1491","4":"1149","5":"2441","6":"820","7":"2633","8":"22015","9":"0","10":"1052","11":"1350","12":"142","13":"430","14":"681","15":"488","16":"183","17":"35352"},{"1":"5GPER","2":"6516","3":"4066","4":"11729","5":"2929","6":"5081","7":"7006","8":"2631","9":"867","10":"0","11":"41320","12":"1018","13":"1805","14":"1300","15":"413","16":"1666","17":"88347"},{"1":"5RWAU","2":"714","3":"2242","4":"1490","5":"1813","6":"1137","7":"4328","8":"807","9":"982","10":"42146","11":"0","12":"277","13":"1163","14":"1090","15":"623","16":"256","17":"59068"},{"1":"6GHOB","2":"1224","3":"1000","4":"3016","5":"622","6":"1307","7":"1804","8":"533","9":"106","10":"899","11":"363","12":"0","13":"5025","14":"190","15":"115","16":"565","17":"16769"},{"1":"6RTAS","2":"1024","3":"1866","4":"2639","5":"1636","6":"1543","7":"2883","8":"651","9":"342","10":"1210","11":"1032","12":"7215","13":"0","14":"268","15":"170","16":"292","17":"22771"},{"1":"7GDAR","2":"1238","3":"2178","4":"1953","5":"1480","6":"2769","7":"5108","8":"2105","9":"641","10":"2152","11":"954","12":"243","13":"335","14":"0","15":"1996","16":"832","17":"23984"},{"1":"7RNTE","2":"406","3":"1432","4":"700","5":"792","6":"896","7":"3018","8":"1296","9":"961","10":"699","11":"826","12":"96","13":"213","14":"2684","15":"0","16":"229","17":"14248"},{"1":"8ACTE","2":"6662","3":"15399","4":"5229","5":"1204","6":"4331","7":"3954","8":"1359","9":"134","10":"1514","11":"285","12":"369","13":"270","14":"617","15":"211","16":"0","17":"41538"},{"1":"(all)","2":"119308","3":"190047","4":"145089","5":"115683","6":"159319","7":"210448","8":"57139","9":"38179","10":"94040","11":"64449","12":"18268","13":"23365","14":"21423","15":"11970","16":"44791","17":"1313518"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

and we can test the goodness-of-fit in exactly the same way as before:

``` r
#use the functions from the last practical to calculate some goodness-of-fit statistics
CalcRSquared(mdatasub$Flow,mdatasub$doubsimFitted)
```

    ## [1] 0.8662571

``` r
CalcRMSE(mdatasub$Flow,mdatasub$doubsimFitted)
```

    ## [1] 4877.799

So the goodness of fit has shot up and we can clearly see the origin and destination constraints working, and for most sets of flows, the model is now producing some good estimates. However, there are still some errors in the flows.

Is there anything more we can do? Yes, of course there is.

### 4.1 Tweaking our Models

#### 4.1.1 Distance Decay

Now, all of the way through these practicals, we have assumed that the distance decay parameter follows a negative power law. Well, it doesn't need to.

In [Wilson's original paper](http://journals.sagepub.com/doi/abs/10.1068/a030001), he generalised the distance decay parameter to:

*f*(*d*<sub>*i**j*</sub>)

Where *f* represents some function of distance describing the rate at which the flow interactions change as distance increases. Lots of people have written about this, including [Tayor (1971)](http://onlinelibrary.wiley.com/doi/10.1111/j.1538-4632.1971.tb00364.x/full) and more recently Robin Lovelace in a transport context, [here](https://www.slideshare.net/ITSLeeds/estimating-distance-decay-for-the-national-propensity-to-cycle-tool).

For the inverse power law that we have been using is one possible function of distance, the other common one that is used is the negative exponential function:

*e**x**p*(−*β**d*<sub>*i**j*</sub>)

We can get a feel for how different distance decay parameters work by plotting some sample data (try different parameters):

``` r
xdistance <- seq(1,20,by=1)
InvPower2 <- xdistance^-2
NegExp0.3 <- exp(-0.3*xdistance)

df <- cbind(InvPower2,NegExp0.3)
meltdf <- melt(df)
ggplot(meltdf,aes(Var1,value, colour = Var2)) + geom_line()
```

![](SimAus2_files/figure-markdown_github-ascii_identifiers/unnamed-chunk-63-1.png)

There is no hard and fast rule as to which function to pick, it will just come down to which fits the data better...

As [Tayor Oshan points out in his excellent Primer](http://openjournals.wu.ac.at/region/paper_175/175.html) what this means in our Poisson regression model is that we simply substitute −*β*ln*d*<sub>*i**j*</sub> for −*β**d*<sub>*i**j*</sub> in our model:

``` r
#run a production constrained SIM
doubSim1 <- glm(Flow ~ Orig_code+Dest_code+dist, na.action = na.exclude, family = poisson(link = "log"), data = mdatasub)
#let's have a look at it's summary...
summary(doubSim1)
```

    ## 
    ## Call:
    ## glm(formula = Flow ~ Orig_code + Dest_code + dist, family = poisson(link = "log"), 
    ##     data = mdatasub, na.action = na.exclude)
    ## 
    ## Deviance Residuals: 
    ##      Min        1Q    Median        3Q       Max  
    ## -127.953   -31.964    -4.223    22.000   224.899  
    ## 
    ## Coefficients:
    ##                    Estimate   Std. Error  z value            Pr(>|z|)    
    ## (Intercept)    11.029397190  0.004029311 2737.291 <0.0000000000000002 ***
    ## Orig_code1RNSW -0.232931197  0.003365487  -69.212 <0.0000000000000002 ***
    ## Orig_code2GMEL -0.169027017  0.003437111  -49.177 <0.0000000000000002 ***
    ## Orig_code2RVIC -0.848474865  0.004000257 -212.105 <0.0000000000000002 ***
    ## Orig_code3GBRI  0.031458158  0.003528225    8.916 <0.0000000000000002 ***
    ## Orig_code3RQLD  0.545438193  0.003552599  153.532 <0.0000000000000002 ***
    ## Orig_code4GADE -0.953678183  0.004453461 -214.143 <0.0000000000000002 ***
    ## Orig_code4RSAU -1.525491034  0.005851357 -260.707 <0.0000000000000002 ***
    ## Orig_code5GPER  1.018132074  0.005249231  193.958 <0.0000000000000002 ***
    ## Orig_code5RWAU -0.712777628  0.005632456 -126.548 <0.0000000000000002 ***
    ## Orig_code6GHOB -2.065433572  0.008093141 -255.208 <0.0000000000000002 ***
    ## Orig_code6RTAS -1.875631590  0.007043234 -266.303 <0.0000000000000002 ***
    ## Orig_code7GDAR -0.660220121  0.007197390  -91.730 <0.0000000000000002 ***
    ## Orig_code7RNTE -2.069001713  0.008823788 -234.480 <0.0000000000000002 ***
    ## Orig_code8ACTE -1.770587265  0.005422542 -326.524 <0.0000000000000002 ***
    ## Dest_code1RNSW  0.308991881  0.003792573   81.473 <0.0000000000000002 ***
    ## Dest_code2GMEL  0.215372964  0.004000059   53.842 <0.0000000000000002 ***
    ## Dest_code2RVIC -0.219333253  0.004195962  -52.272 <0.0000000000000002 ***
    ## Dest_code3GBRI  0.567396219  0.003962006  143.209 <0.0000000000000002 ***
    ## Dest_code3RQLD  1.269837230  0.003852586  329.606 <0.0000000000000002 ***
    ## Dest_code4GADE -0.635996028  0.005149708 -123.501 <0.0000000000000002 ***
    ## Dest_code4RSAU -0.907190511  0.005981607 -151.663 <0.0000000000000002 ***
    ## Dest_code5GPER  1.692278631  0.005566703  304.000 <0.0000000000000002 ***
    ## Dest_code5RWAU  0.009057805  0.005795159    1.563               0.118    
    ## Dest_code6GHOB -1.543434710  0.008006753 -192.767 <0.0000000000000002 ***
    ## Dest_code6RTAS -1.407712782  0.007211432 -195.206 <0.0000000000000002 ***
    ## Dest_code7GDAR -0.146531215  0.007831492  -18.711 <0.0000000000000002 ***
    ## Dest_code7RNTE -1.631352259  0.009752794 -167.270 <0.0000000000000002 ***
    ## Dest_code8ACTE -1.281496564  0.005597280 -228.950 <0.0000000000000002 ***
    ## dist           -0.001392048  0.000001858 -749.415 <0.0000000000000002 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for poisson family taken to be 1)
    ## 
    ##     Null deviance: 2750417  on 209  degrees of freedom
    ## Residual deviance:  521907  on 180  degrees of freedom
    ## AIC: 523966
    ## 
    ## Number of Fisher Scoring iterations: 6

``` r
mdatasub$doubsimFitted1 <- round(fitted(doubSim1),0)
```

``` r
CalcRSquared(mdatasub$Flow,mdatasub$doubsimFitted1)
```

    ## [1] 0.7591672

``` r
CalcRMSE(mdatasub$Total,mdatasub$doubsimFitted1)
```

    ## [1] NaN

So, it would appear that in this case using a negative exponential function in our model results in a worse outcome than the initial inverse power law - this may not always be the case, so it is worth experimenting.

#### 4.1.2 Adding more explanatory variables

Yes, the nice thing about doing all of this in a regression modelling framework is we can just keep adding predictor variables into the mix and seeing whether they have an effect.

You can't add origin or destination specific predictors into a doubly constrained model like this, however, switching back to the singly constrained models, as many different origin or destination predictor variables can be added as seems reasonable (subject to the usual restrictions on high correlation)

``` r
kitchensinkSIM <- glm(Flow ~ Dest_code + vi1_origpop + vi2_origunemp + vi3_origmedinc + vi4_origpctrent -1, na.action = na.exclude, family = poisson(link = "log"), data = mdatasub)
#let's have a look at it's summary...
summary(kitchensinkSIM)
```

    ## 
    ## Call:
    ## glm(formula = Flow ~ Dest_code + vi1_origpop + vi2_origunemp + 
    ##     vi3_origmedinc + vi4_origpctrent - 1, family = poisson(link = "log"), 
    ##     data = mdatasub, na.action = na.exclude)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -157.58   -50.78   -25.36    -1.61   376.17  
    ## 
    ## Coefficients:
    ##                         Estimate       Std. Error z value
    ## Dest_code1GSYD   8.5079198832974  0.0092725941386  917.53
    ## Dest_code1RNSW   8.8509342261089  0.0093023938242  951.47
    ## Dest_code2GMEL   8.6605325435237  0.0095763427883  904.37
    ## Dest_code2RVIC   8.3148467766947  0.0095514832591  870.53
    ## Dest_code3GBRI   8.6505388411216  0.0092944957235  930.72
    ## Dest_code3RQLD   8.9308388526230  0.0092755516855  962.84
    ## Dest_code4GADE   7.6026326757955  0.0099718021347  762.41
    ## Dest_code4RSAU   7.1849348979560  0.0103966617993  691.08
    ## Dest_code5GPER   8.1156642997172  0.0096290001352  842.84
    ## Dest_code5RWAU   7.7055406753879  0.0098684431689  780.83
    ## Dest_code6GHOB   6.4441629668622  0.0116864502641  551.42
    ## Dest_code6RTAS   6.6977262590540  0.0111185062591  602.39
    ## Dest_code7GDAR   6.5928446625064  0.0113331736058  581.73
    ## Dest_code7RNTE   6.0103621967506  0.0127994818256  469.58
    ## Dest_code8ACTE   7.3398091379766  0.0102203937757  718.15
    ## vi1_origpop      0.0000004240122  0.0000000005802  730.74
    ## vi2_origunemp    0.0708869917906  0.0013751762909   51.55
    ## vi3_origmedinc   0.0002931526306  0.0000071375273   41.07
    ## vi4_origpctrent -0.0223901825968  0.0002265287431  -98.84
    ##                            Pr(>|z|)    
    ## Dest_code1GSYD  <0.0000000000000002 ***
    ## Dest_code1RNSW  <0.0000000000000002 ***
    ## Dest_code2GMEL  <0.0000000000000002 ***
    ## Dest_code2RVIC  <0.0000000000000002 ***
    ## Dest_code3GBRI  <0.0000000000000002 ***
    ## Dest_code3RQLD  <0.0000000000000002 ***
    ## Dest_code4GADE  <0.0000000000000002 ***
    ## Dest_code4RSAU  <0.0000000000000002 ***
    ## Dest_code5GPER  <0.0000000000000002 ***
    ## Dest_code5RWAU  <0.0000000000000002 ***
    ## Dest_code6GHOB  <0.0000000000000002 ***
    ## Dest_code6RTAS  <0.0000000000000002 ***
    ## Dest_code7GDAR  <0.0000000000000002 ***
    ## Dest_code7RNTE  <0.0000000000000002 ***
    ## Dest_code8ACTE  <0.0000000000000002 ***
    ## vi1_origpop     <0.0000000000000002 ***
    ## vi2_origunemp   <0.0000000000000002 ***
    ## vi3_origmedinc  <0.0000000000000002 ***
    ## vi4_origpctrent <0.0000000000000002 ***
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for poisson family taken to be 1)
    ## 
    ##     Null deviance: 23087017  on 210  degrees of freedom
    ## Residual deviance:  1441432  on 191  degrees of freedom
    ## AIC: 1443469
    ## 
    ## Number of Fisher Scoring iterations: 6

### 4.2 From Poisson Regression back to Entropy

As with the earlier models, I have shown you how you can plug the parameter estimates back into Wilson's entropy maximising multiplicative models in order to generate estimates and tweak things still further.

If you remember from Equations 11 and 12 above, the key to the doubly constrained models is the *A*<sub>*i*</sub> and *B*<sub>*j*</sub> balancing factors and as they rely on each other, they need to be calculated iteratively. We can do this using [Senior's algorthm](http://journals.sagepub.com/doi/abs/10.1177/030913257900300218) also mentioned earlier.

Here is the algorithm in R... (I wrote this code way back in 2012, so it's a bit ropey, but it works...) To run it, hightlight the whole thing and run it all at once.

After it works, you can spend some time working out what is going on. I find the best solution is to try and run elements of the code individually to see what is happening...

``` r
##########################################################################
#This block of code will calculate balancing factors for an entropy
#maximising model (doubly constrained)

#set beta to the appropriate value according to whether exponential or power
if(tail(names(coef(doubSim)),1)=="dist"){
  mdatasub$beta <- coef(doubSim)["dist"]
  disdecay = 0
} else {
  mdatasub$beta <- coef(doubSim)["log(dist)"]
  disdecay = 1
}

#Create some new Ai and Bj columns and fill them with starting values
mdatasub$Ai <- 1
mdatasub$Bj <- 1
mdatasub$OldAi <- 10
mdatasub$OldBj <- 10
mdatasub$diff <- abs((mdatasub$OldAi-mdatasub$Ai)/mdatasub$OldAi)

#create convergence and iteration variables and give them initial values
cnvg = 1
its = 0

#This is a while-loop which will calculate Orig and Dest balancing
#factors until the specified convergence criteria is met
while(cnvg > 0.001){
  print(paste0("iteration ", its))
  its = its + 1 #increment the iteration counter by 1
  #First some initial calculations for Ai...
  if(disdecay==0){
    mdatasub$Ai <- (mdatasub$Bj*mdatasub$D_j*exp(mdatasub$dist*mdatasub$beta))
  } else {
    mdatasub$Ai <- (mdatasub$Bj*mdatasub$D_j*exp(log(mdatasub$dist)*mdatasub$beta))
  }  
  #aggregate the results by your Origs and store in a new dataframe
  AiBF <- aggregate(Ai ~ Orig_code, data = mdatasub, sum)
  #now divide by 1
  AiBF$Ai <- 1/AiBF$Ai 
  #and replace the initial values with the new balancing factors
  updates = AiBF[match(mdatasub$Orig_code,AiBF$Orig_code),"Ai"]
  mdatasub$Ai = ifelse(!is.na(updates), updates, mdatasub$Ai)
  #now, if not the first iteration, calculate the difference between  the new Ai values and the old Ai values and once done, overwrite the old Ai values with the new ones. 
  if(its==1){
    mdatasub$OldAi <- mdatasub$Ai    
  } else {
    mdatasub$diff <- abs((mdatasub$OldAi-mdatasub$Ai)/mdatasub$OldAi)    
    mdatasub$OldAi <- mdatasub$Ai
  }
  
  #Now some similar calculations for Bj...
  if(disdecay==0){
    mdatasub$Bj <- (mdatasub$Ai*mdatasub$O_i*exp(mdatasub$dist*mdatasub$beta))
  } else {
    mdatasub$Bj <- (mdatasub$Ai*mdatasub$O_i*exp(log(mdatasub$dist)*mdatasub$beta))
  }
  #aggregate the results by your Dests and store in a new dataframe
  BjBF <- aggregate(Bj ~ Dest_code, data = mdatasub, sum)
  #now divide by 1
  BjBF$Bj <- 1/BjBF$Bj  
  #and replace the initial values by the balancing factor
  updates = BjBF[match(mdatasub$Dest_code,BjBF$Dest_code),"Bj"]
  mdatasub$Bj = ifelse(!is.na(updates), updates, mdatasub$Bj)
#now, if not the first iteration, calculate the difference between the new Bj values and the old Bj values and once done, overwrite the old Bj values with the new ones.
  if(its==1){
    mdatasub$OldBj <- mdatasub$Bj
  } else {
    mdatasub$diff <- abs((mdatasub$OldBj-mdatasub$Bj)/mdatasub$OldBj)    
    mdatasub$OldBj <- mdatasub$Bj
  } 
  #overwrite the convergence variable with 
  cnvg = sum(mdatasub$diff)
}
```

    ## [1] "iteration 0"
    ## [1] "iteration 1"
    ## [1] "iteration 2"
    ## [1] "iteration 3"
    ## [1] "iteration 4"
    ## [1] "iteration 5"
    ## [1] "iteration 6"
    ## [1] "iteration 7"
    ## [1] "iteration 8"
    ## [1] "iteration 9"

So, we've calculated our *A*<sub>*i*</sub> and *B*<sub>*j*</sub> values using out iterative routine - now we can plug them back into our model, to prove, once again, that the Poisson Model is exactly the same as the multiplicative Entropy Maximising Model...

``` r
########################################################################
#Now create some SIM estimates
if(disdecay==0){
  mdatasub$SIM_Estimates <- (mdatasub$O_i*mdatasub$Ai*mdatasub$D_j*mdatasub$Bj*exp(mdatasub$dist*mdatasub$beta))
} else{
  mdatasub$SIM_Estimates_pow <- (mdatasub$O_i*mdatasub$Ai*mdatasub$D_j*mdatasub$Bj*exp(log(mdatasub$dist)*mdatasub$beta))
}
########################################################################
```

``` r
mdatasub$SIM_Estimates_pow <- round(mdatasub$SIM_Estimates_pow,0)
mdatasubmat8 <- dcast(mdatasub, Orig_code ~ Dest_code, sum, value.var = "SIM_Estimates_pow", margins=c("Orig_code", "Dest_code"))
mdatasubmat8
```

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["Orig_code"],"name":[1],"type":["fctr"],"align":["left"]},{"label":["1GSYD"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["1RNSW"],"name":[3],"type":["dbl"],"align":["right"]},{"label":["2GMEL"],"name":[4],"type":["dbl"],"align":["right"]},{"label":["2RVIC"],"name":[5],"type":["dbl"],"align":["right"]},{"label":["3GBRI"],"name":[6],"type":["dbl"],"align":["right"]},{"label":["3RQLD"],"name":[7],"type":["dbl"],"align":["right"]},{"label":["4GADE"],"name":[8],"type":["dbl"],"align":["right"]},{"label":["4RSAU"],"name":[9],"type":["dbl"],"align":["right"]},{"label":["5GPER"],"name":[10],"type":["dbl"],"align":["right"]},{"label":["5RWAU"],"name":[11],"type":["dbl"],"align":["right"]},{"label":["6GHOB"],"name":[12],"type":["dbl"],"align":["right"]},{"label":["6RTAS"],"name":[13],"type":["dbl"],"align":["right"]},{"label":["7GDAR"],"name":[14],"type":["dbl"],"align":["right"]},{"label":["7RNTE"],"name":[15],"type":["dbl"],"align":["right"]},{"label":["8ACTE"],"name":[16],"type":["dbl"],"align":["right"]},{"label":["(all)"],"name":[17],"type":["dbl"],"align":["right"]}],"data":[{"1":"1GSYD","2":"0","3":"66903","4":"18581","5":"8510","6":"39179","7":"27666","8":"6190","9":"2981","10":"6373","11":"2758","12":"1712","13":"2384","14":"1266","15":"620","16":"19698","17":"204821"},{"1":"1RNSW","2":"40099","3":"0","4":"18006","5":"10062","6":"31574","7":"35342","8":"8897","9":"4252","10":"6711","11":"3060","12":"1265","13":"1821","14":"1369","15":"727","16":"8174","17":"171359"},{"1":"2GMEL","2":"11868","3":"19189","4":"0","5":"72706","6":"9037","7":"12748","8":"9040","9":"2545","10":"5291","11":"2121","12":"2677","13":"4705","14":"782","15":"393","16":"5470","17":"158572"},{"1":"2RVIC","2":"4429","3":"8737","4":"59237","5":"0","6":"3567","7":"5329","8":"4629","9":"1146","10":"2097","11":"860","12":"740","13":"1229","14":"315","15":"162","16":"1901","17":"94378"},{"1":"3GBRI","2":"22501","3":"30254","4":"8125","5":"3937","6":"0","7":"59334","8":"4650","9":"3116","10":"7027","11":"3285","12":"969","13":"1299","14":"1879","15":"897","16":"3134","17":"150407"},{"1":"3RQLD","2":"13155","3":"28037","4":"9490","5":"4869","6":"49124","7":"0","8":"8534","9":"8930","10":"15802","11":"8866","12":"1105","13":"1500","14":"6483","15":"3921","16":"2558","17":"162374"},{"1":"4GADE","2":"4392","3":"10534","4":"10043","5":"6311","6":"5745","7":"12736","8":"0","9":"6216","10":"6328","11":"2743","12":"751","13":"1125","14":"845","15":"479","16":"1281","17":"69529"},{"1":"4RSAU","2":"1601","3":"3809","4":"2139","5":"1183","6":"2914","7":"10085","8":"4704","9":"0","10":"4312","11":"2452","12":"220","13":"310","14":"720","15":"509","16":"394","17":"35352"},{"1":"5GPER","2":"3336","3":"5860","4":"4336","5":"2109","6":"6404","7":"17395","8":"4668","9":"4203","10":"0","11":"32886","12":"682","13":"906","14":"3352","15":"1405","16":"806","17":"88348"},{"1":"5RWAU","2":"1390","3":"2573","4":"1673","5":"833","6":"2883","7":"9398","8":"1948","9":"2302","10":"31670","11":"0","12":"239","13":"321","14":"2379","15":"1131","16":"327","17":"59067"},{"1":"6GHOB","2":"954","3":"1176","4":"2336","5":"793","6":"940","7":"1295","8":"589","9":"228","10":"727","11":"265","12":"0","13":"7014","14":"96","15":"45","16":"311","17":"16769"},{"1":"6RTAS","2":"1398","3":"1781","4":"4318","5":"1384","6":"1326","7":"1850","8":"929","9":"339","10":"1015","11":"373","12":"7380","13":"0","14":"135","15":"63","16":"480","17":"22771"},{"1":"7GDAR","2":"776","3":"1401","4":"751","5":"371","6":"2007","7":"8361","8":"730","9":"822","10":"3927","11":"2894","12":"106","13":"141","14":"0","15":"1529","16":"169","17":"23985"},{"1":"7RNTE","2":"403","3":"788","4":"400","5":"202","6":"1014","7":"5356","8":"438","9":"615","10":"1743","11":"1458","12":"52","13":"70","14":"1620","15":"0","16":"88","17":"14247"},{"1":"8ACTE","2":"13007","3":"9006","4":"5655","5":"2412","6":"3603","7":"3552","8":"1192","9":"485","10":"1017","11":"428","12":"368","13":"540","14":"182","15":"90","16":"0","17":"41537"},{"1":"(all)","2":"119309","3":"190048","4":"145090","5":"115682","6":"159317","7":"210447","8":"57138","9":"38180","10":"94040","11":"64449","12":"18266","13":"23365","14":"21423","15":"11971","16":"44791","17":"1313516"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

Are the the same? Yes!! Woo hoo.

5. Conclusions, further notes and ideas for additional activities
-----------------------------------------------------------------

Hopefully you have now seen how it is extremely straight-forward to run and calibrate Wilson's full family of Spatial Interaction Models in R using GLM and Poisson Regression.

### 5.1 Some Further Notes

Now might be the time to mention that despite everything I've shown you, there has been some discussion in the literature as to whether the Poisson Model is actually a misspecification, especially for modelling migration flows. If you have the stomach for it, [this paper by Congdon goes into a lot of detail](http://journals.sagepub.com/doi/abs/10.1068/a251481).

The issue is a thing called 'overdispersion' which, translated, essentially relates to the model not being able to capture all of the things that could be explaining the flows in the independent variables that are supplied to the model. The details are tedious and only really intelligible to those with a statistics background. If you want a starter, [try here](https://en.wikipedia.org/wiki/Overdispersion), but in practical terms, we can get around this problem by fitting a very similar sort of regression model called the *negative binomial* regression model.

If you wish, you can read up and experiment with this model - you can fit it in exactly the same way as the `glm` model but using a function called `glm.nb` which is part of the `mass` package. The negative binomial model has an extra parameter in the model for overdispersion. You you do try this, you will almost certainly discover that your results barely change - but hell, you might keep a pedantic reviewer at bay if you submit this to a journal (not that I'm speaking from experience or anything).

### And some more comments

Another thing to note is that the example we used here had quite neat data. You will almost certainly run into problems if you have sparse data or predictors with 0s in them. If this happens, then you might need to either drop some rows in your data (if populated with 0s) or substitute 0s for very small numbers, much less than 1, but greater than 0 (this is because you can't take the log of 0)

And another thing to note is that the models in this Australian example assumed that the flow data and predictors were all in and around the same order or magnitude. This is not necessarily the case, particularly with a 5 year migration transition and some large metropolitan areas. Where data that (such as population masses at origins and destinations) that are an order of magnitude different (i.e. populations about ten times larger in different locations) then the model estimates might be biased. Fortunately, there are packages available to help us with these problems as well. The [`robustbase` package](https://cran.r-project.org/web/packages/robustbase/index.html) features a function called `glmrob` which will deal with this issues (again, your results probably won't change much, but worth knowing).
