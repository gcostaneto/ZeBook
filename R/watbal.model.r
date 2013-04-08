################################################################################
# "Working with dynamic models for agriculture"
# R script for practical work
# Daniel Wallach (INRA), David Makowski (INRA), James W. Jones (U.of Florida),
# Francois Brun (ACTA), Sylvain Toulet (INRA, internship 2012)
# version : 2012-04-23
# Model described in the book, Appendix. Models used as illustrative examples: description and R code
################################ FUNCTIONS #####################################
################################################################################
#' @title Water Balance model function - Update
#' @param WAT0 : Water at the beginning of the day (mm).
#' @param RAIN : Rainfall of day (mm)
#' @param ETr : Evapotranspiration of day (mm)
#' @param param : a vector of parameters
#' @param FC : Water content at field capacity (cm^3.cm^-3)
#' @param WP : Water content at wilting Point (cm^3.cm^-3)
#' @return WAT1 : Water at the beginning of the day+1 (mm).
#' @export
watbal.update = function(WAT0,RAIN, ETr,param,WP,FC){
  WHC =(param["WHC"])
	MUF = (param["MUF"])
	DC = (param["DC"])
	z = (param["z"])
	CN = (param["CN"])
	# Maximum abstraction (for run off)
	S = 25400/CN-254
	# Initial Abstraction (for run off)
	IA = 0.2*S
  # WATfc : Maximum Water content at field capacity (mm)
  WATfc = FC*z
  # WATwp : Water content at wilting Point (mm)
  WATwp = WP*z
  # Change in Water Before Drainage (Precipitation - Runoff)
	if (RAIN>IA){RO = (RAIN-0.2*S)^2/(RAIN+0.8*S)}else{RO = 0}
  # Calculating the amount of deep drainage
  if (WAT0+RAIN-RO > WATfc){DR = DC*(WAT0+RAIN-RO-WATfc)}else{DR = 0}
	# Calculating the amount of water lost by transpiration (after drainage)

  TR = min(MUF*(WAT0+RAIN-RO-DR-WATwp), ETr)

	dWAT = RAIN - RO -DR -TR
  WAT1 = WAT0 + dWAT
  return(WAT1)
}
################################################################################
#' @title Water Balance model function - Integration loop
#' @param param : a vector of parameters
#' @param weather : weather data.frame for one single year
#' @param WP : Water content at wilting Point (cm^3.cm^-3)
#' @param FC : Water content at field capacity (cm^3.cm^-3)
#' @param WAT0 : Initial Water content (mm). If NA WAT0=z*FC
#' @return data.frame with daily RAIN, ETR, Water at the beginning of the day (absolute : WAT, mm and relative value : WATp, -)
#' @export
watbal.model = function(param, weather, WP, FC, WAT0=NA)
{
  z = (param["z"])
  # input variable describing the soil
	# WP : Water content at wilting Point (cm^3.cm^-3)
	# FC : Water content at field capacity (cm^3.cm^-3)
	# WAT0 : Initial Water content (mm)
	if (is.na(WAT0)) {WAT0 = z*FC}
	# Initialize variable
  # WAT : Water at the beginning of the day (mm) : State variable
  WAT = rep(NA, nrow(weather))

  # initialisation use Amount of water at the beginning
  WAT[1]=WAT0
  # integration loops
  for (day in 1:(nrow(weather)-1))
	{
    WAT[day+1]= watbal.update(WAT[day],weather$RAIN[day], weather$ETr[day],param,WP,FC)[1]
	}
  # Volumetric Soil Water content (fraction : mm.mm-1)
  WATp=WAT/z
	return(data.frame(day = weather$day, RAIN = weather$RAIN, ETr = weather$ETr, WAT = WAT, WATp=WATp));
}

################################################################################
#' @title Define parameter values of the Water Balance model
#' @return matrix with parameter values (nominal, binf, bsup)
#' @export
watbal.define.param = function()
{
	# nominal, binf, bsup
	# WHC  : Water Holding Capacity of the soil (cm^3 cm^-3)
	WHC = c(0.13, 0.05, 0.18);
	# MUF : Water Uptake coefficient (mm^3 mm^-3)
	MUF = c(0.096, 0.06, 0.11);
	# DC :  Drainage coefficient (mm^3 mm^-3)
	DC = c(0.55, 0.25, 0.75);
	# z : root zone depth (mm)
	z = c(400, 300, 600);
	# CN : Runoff curve number
	CN = c(65, 15, 90); # nominal = 58 in the description ??
	
	param = data.frame(WHC, MUF, DC, z, CN);
	row.names(param) = c("nominal","binf","bsup");
	param = as.matrix(param)
  attributes(param)$description=t(t(c("WHC"="Water Holding Capacity of the soil (cm3.cm-3)",
  "MUF" = "Water Uptake coefficient (mm^3 mm^-3)", "DC" = "Drainage coefficient (mm3.mm-3)",
  "z" = "root zone depth (mm)",  "CN" = "Runoff curve number")))
	return(param)
}

################################################################################
#' @title Reading Weather data function for Water Balance model (West of France Weather)
#' @param working.year : year for the subset of weather data (default=NA : all the year)
#' @param working.site : site for the subset of weather data (default=NA : all the site)
#' @return data.frame with daily weather data for one or several site(s) and for one or several year(s)
#' @export
# Reading Weather data function
watbal.weather = function(working.year=NA, working.site=NA)
    {
    #day month year R Tmax Tmin rain ETP
    # R : solar radiation (MJ)
    # Tmax : maximum temperature (°C)
    # Tmin : minimum temperature (°C)
    weather=weather_FranceWest
    names(weather)[names(weather)=="WEDAY"]= "day"
    names(weather)[names(weather)=="WEYR"]= "year"
    names(weather)[names(weather)=="SRAD"]= "I"
    names(weather)[names(weather)=="TMAX"]= "Tmax"
    names(weather)[names(weather)=="RAIN"]= "RAIN"
    names(weather)[names(weather)=="ETr"]= "ETr"
    # if argument working.year/working.site is specified, work on one particular year/site
    if (!is.na(working.year)&!is.na(working.site)) {weather=weather[(weather$year==working.year)&(weather$idsite==working.site),] }
    else{
      if (!is.na(working.year)) {weather<-weather[(weather$year==working.year),]}
      if (!is.na(working.site)) {weather<-weather[(weather$idsite==working.site),]}}
    return (weather)
    }
################################################################################
# End of file