
<!-- README.md is generated from README.Rmd. Please edit that file -->
PREMIS-ghg
==========

### Soil GHG experiment

#### Motivation

Disturbances such as sea level rise, increased extreme weather events, and climate change can have lasting impacts on terrestrial ecosystems. Monitoring greenhouse gas fluxes at the terrestrial-aquatic interface offers a way to quantify the stability and resilience of terrestrial soils in a stressed environment.

#### Design

We are testing soil response to salt water intrusion by monitoring soil respiration rates along a creek transect at the [Smithsonian Environmental Research Center (SERC)](https://serc.si.edu/). We have transplanted soil cores (40 cm diameter, 20 cm depth) along a salinity and elevation gradient at three locations (~1 km between salinity plots, ~50 m between elevation plots). This design will also be replicated on the west coast at Beaver Creek. We hypothesize that an increase in salinity will *suppress* soil CO2 respiration, but not affect methane production.

More info [here!](https://osf.io/at9hr)

![](https://github.com/PNNL-PREMIS/PREMIS-ghg/blob/master/photos/cores_in_cart.jpeg) ![](https://github.com/PNNL-PREMIS/PREMIS-ghg/blob/master/photos/BBL_SP_snow.jpeg) ![](https://github.com/PNNL-PREMIS/PREMIS-ghg/blob/master/photos/cores_in_ground.jpeg)

Real-time data diagnostics
==========================

**Last run: Sun Jun 16 04:08:47 2019**

| Site | Experiment           |    N|
|:-----|:---------------------|----:|
| SERC | Control              |   56|
| SERC | Elevation transplant |   32|
| SERC | Salinity transplant  |   36|

IRGA data
---------

### CO2 flux over time

![](README_figures/README-co2_time-1.png)

### Soil temperature versus CO2 flux for all cores

![](README_figures/README-q10-1.png)

### Licor soil moisture over time

    #> Warning: Removed 72 rows containing missing values (geom_point).

![](README_figures/README-licor_sm-1.png)

### Coefficient of variation between collars

![](README_figures/README-collar_cv-1.png)

Weather station data
--------------------

### Soil temperature at 20 cm and 2 cm depth

![](README_figures/README-soil_temp-1.png)

### Air temperature and Relative Humidity

![](README_figures/README-air_temp-1.png)

### Soil moisure at 20CM and 2CM depth

![](README_figures/README-soil_moisture-1.png)

### Stdev for each temperature and moisture probe

    #> # A tibble: 201,733 x 7
    #> # Groups:   Site, Sensor_Depth, Sensor_Group [?]
    #>   Site  Sensor_Depth Sensor_Group Timestamp               n meanValue
    #>   <chr> <chr>        <chr>        <dttm>              <int>     <dbl>
    #> 1 HSLE  20CM         Temp         2018-06-12 13:53:03     1      17.3
    #> 2 HSLE  20CM         Temp         2018-06-12 14:08:03     1      17.3
    #> 3 HSLE  20CM         Temp         2018-06-12 14:23:03     1      17.3
    #> 4 HSLE  20CM         Temp         2018-06-12 14:38:03     1      17.4
    #> 5 HSLE  20CM         Temp         2018-06-12 14:53:03     1      17.4
    #> # … with 2.017e+05 more rows, and 1 more variable: sdValue <dbl>

Wells
-----

### Well conductivity data

    #> Warning: Removed 4 rows containing missing values (geom_path).

![](README_figures/README-wells-1.png)

Other
-----

### Histogram of trees by DBH

    #> Warning: Removed 3 rows containing non-finite values (stat_bin).

![](README_figures/README-inventory-1.png)

### Coming soon: litter data!
