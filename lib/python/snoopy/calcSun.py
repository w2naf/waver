# UTILS/calcSun
"""
*******************************
            calcSun
*******************************
This subpackage contains def to calculate sunrise/sunset

This includes the following defs:
	getJD( date )
		calculate the julian date from a python datetime object
	calcTimeJulianCent( jd )
		convert Julian Day to centuries since J2000.0.
	calcGeomMeanLongSun( t )
		calculate the Geometric Mean Longitude of the Sun (in degrees)
	calcGeomMeanAnomalySun( t )
		calculate the Geometric Mean Anomaly of the Sun (in degrees)
	calcEccentricityEarthOrbit( t )
		calculate the eccentricity of earth's orbit (unitless)
	calcSunEqOfCenter( t )
		calculate the equation of center for the sun (in degrees)
	calcSunTrueLong( t )
		calculate the true longitude of the sun (in degrees)
	calcSunTrueAnomaly( t )
		calculate the true anamoly of the sun (in degrees)
	calcSunRadVector( t )
		calculate the distance to the sun in AU (in degrees)
	calcSunApparentLong( t )
		calculate the apparent longitude of the sun (in degrees)
	calcMeanObliquityOfEcliptic( t )
		calculate the mean obliquity of the ecliptic (in degrees)
	calcObliquityCorrection( t )
		calculate the corrected obliquity of the ecliptic (in degrees)
	calcSunRtAscension( t )
		calculate the right ascension of the sun (in degrees)
	calcSunDeclination( t )
		calculate the declination of the sun (in degrees)
	calcEquationOfTime( t )
		calculate the difference between true solar time and mean solar time (output: equation of time in minutes of time)
	calcHourAngleSunrise( lat, solarDec )
		calculate the hour angle of the sun at sunrise for the latitude (in radians)
	calcAzEl( output, t, localtime, latitude, longitude, zone )
		calculate sun azimuth and zenith angle
	calcSolNoonUTC( jd, longitude )
		calculate time of solar noon the given day at the given location on earth (in minutes since 0 UTC)
	calcSolNoon( jd, longitude, timezone, dst )
		calculate time of solar noon the given day at the given location on earth (in minutes)
	calcSunRiseSetUTC( jd, latitude, longitude )
		calculate sunrise/sunset the given day at the given location on earth (in minutes since 0 UTC)
	calcSunRiseSet( jd, latitude, longitude, timezone, dst )
		calculate sunrise/sunset the given day at the given location on earth (in minutes)
	calcTerminator( jd, latitudes, longitudes )
		calculate terminator position and solar zenith angle for a given julian date-time within latitude/longitude limits
		note that for plotting only, basemap has a built-in terminator

Source: http://www.esrl.noaa.gov/gmd/grad/solcalc/
Translated to Python by Sebastien de Larquier
*******************************
"""
import math
from numpy import array	
from numpy import zeros	
from numpy import linspace
from numpy import argmin

def calcTimeJulianCent( jd ):
	"""
Convert Julian Day to centuries since J2000.0.
	"""
	T = (jd - 2451545.0)/36525.0
	return T


def calcGeomMeanLongSun( t ):
	"""
Calculate the Geometric Mean Longitude of the Sun (in degrees)
	"""
	L0 = 280.46646 + t * ( 36000.76983 + t*0.0003032 )
	while L0 > 360.0:
		L0 -= 360.0
	while L0 < 0.0:
		L0 += 360.0
	return L0 # in degrees


def calcGeomMeanAnomalySun( t ):
	"""
Calculate the Geometric Mean Anomaly of the Sun (in degrees)
	"""
	M = 357.52911 + t * ( 35999.05029 - 0.0001537 * t)
	return M # in degrees


def calcEccentricityEarthOrbit( t ):
	"""
Calculate the eccentricity of earth's orbit (unitless)
	"""
	e = 0.016708634 - t * ( 0.000042037 + 0.0000001267 * t)
	return e # unitless


def calcSunEqOfCenter( t ):
	"""
Calculate the equation of center for the sun (in degrees)
	"""
	mrad = math.radians(calcGeomMeanAnomalySun(t))
	sinm = math.sin(mrad)
	sin2m = math.sin(mrad+mrad)
	sin3m = math.sin(mrad+mrad+mrad)
	C = sinm * (1.914602 - t * (0.004817 + 0.000014 * t)) + sin2m * (0.019993 - 0.000101 * t) + sin3m * 0.000289
	return C # in degrees


def calcSunTrueLong( t ):
	"""
Calculate the true longitude of the sun (in degrees)
	"""
	l0 = calcGeomMeanLongSun(t)
	c = calcSunEqOfCenter(t)
	O = l0 + c
	return O # in degrees


def calcSunTrueAnomaly( t ):
	"""
Calculate the true anamoly of the sun (in degrees)
	"""
	m = calcGeomMeanAnomalySun(t)
	c = calcSunEqOfCenter(t)
	v = m + c
	return v # in degrees


def calcSunRadVector( t ):
	"""
Calculate the distance to the sun in AU (in degrees)
	"""
	v = calcSunTrueAnomaly(t)
	e = calcEccentricityEarthOrbit(t)
	R = (1.000001018 * (1. - e * e)) / ( 1. + e * math.cos( math.radians(v) ) )
	return R # n AUs


def calcSunApparentLong( t ):
	"""
Calculate the apparent longitude of the sun (in degrees)
	"""
	o = calcSunTrueLong(t)
	omega = 125.04 - 1934.136 * t
	SunLong = o - 0.00569 - 0.00478 * math.sin(math.radians(omega))
	return SunLong # in degrees


def calcMeanObliquityOfEcliptic( t ):
	"""
Calculate the mean obliquity of the ecliptic (in degrees)
	"""
	seconds = 21.448 - t*(46.8150 + t*(0.00059 - t*(0.001813)))
	e0 = 23.0 + (26.0 + (seconds/60.0))/60.0
	return e0 # in degrees


def calcObliquityCorrection( t ):
	"""
Calculate the corrected obliquity of the ecliptic (in degrees)
	"""
	e0 = calcMeanObliquityOfEcliptic(t)
	omega = 125.04 - 1934.136 * t
	e = e0 + 0.00256 * math.cos(math.radians(omega))
	return e # in degrees


def calcSunRtAscension( t ):
	"""
Calculate the right ascension of the sun (in degrees)
	"""
	e = calcObliquityCorrection(t)
	SunLong = calcSunApparentLong(t)
	tananum = ( math.cos(math.radians(e)) * math.sin(math.radians(SunLong)) )
	tanadenom = math.cos(math.radians(SunLong))
	alpha = math.degrees(amath.atan2(tananum, tanadenom))
	return alpha # in degrees


def calcSunDeclination( t ):
	"""
Calculate the declination of the sun (in degrees)
	"""
	e = calcObliquityCorrection(t)
	SunLong = calcSunApparentLong(t)
	sint = math.sin(math.radians(e)) * math.sin(math.radians(SunLong))
	theta = math.degrees(math.asin(sint))
	return theta # in degrees


def calcEquationOfTime( t ):
	"""
Calculate the difference between true solar time and mean solar time (output: equation of time in minutes of time)	
	"""
	epsilon = calcObliquityCorrection(t)
	l0 = calcGeomMeanLongSun(t)
	e = calcEccentricityEarthOrbit(t)
	m = calcGeomMeanAnomalySun(t)
	y = math.tan(math.radians(epsilon/2.0))
	y *= y

	sin2l0 = math.sin(math.radians(2.0 * l0))
	sinm   = math.sin(math.radians(m))
	cos2l0 = math.cos(math.radians(2.0 * l0))
	sin4l0 = math.sin(math.radians(4.0 * l0))
	sin2m  = math.sin(math.radians(2.0 * m))

	Etime = y * sin2l0 - 2.0 * e * sinm + 4.0 * e * y * sinm * cos2l0 - 0.5 * y * y * sin4l0 - 1.25 * e * e * sin2m
	return math.degrees(Etime*4.0) # in minutes of time


def calcHourAngleSunrise( lat, solarDec ):
	"""
Calculate the hour angle of the sun at sunrise for the latitude (in radians)
	"""
	latRad = math.radians(lat)
	sdRad  = math.radians(solarDec)
	HAarg = math.cos(math.radians(90.833)) / ( math.cos(latRad)*math.cos(sdRad) ) - math.tan(latRad) * math.tan(sdRad)
	HA = math.acos(HAarg);
	return HA # in radians (for sunset, use -HA)


def calcAzEl( t, localtime, latitude, longitude, zone ):
	"""
Calculate sun azimuth and zenith angle
	"""
	eqTime = calcEquationOfTime(t)
	theta  = calcSunDeclination(t)

	solarTimeFix = eqTime + 4.0 * longitude - 60.0 * zone
	earthRadVec = calcSunRadVector(t)

	trueSolarTime = localtime + solarTimeFix
	while trueSolarTime > 1440:
		trueSolarTime -= 1440.

	hourAngle = trueSolarTime / 4.0 - 180.0
	if hourAngle < -180.: 
		hourAngle += 360.0

	haRad = math.radians(hourAngle)
	csz = math.sin(math.radians(latitude)) * math.sin(math.radians(theta)) + math.cos(math.radians(latitude)) * math.cos(math.radians(theta)) * math.cos(haRad)
	if csz > 1.0: 
		csz = 1.0 
	elif csz < -1.0: 
		csz = -1.0
	zenith = math.degrees(math.acos(csz))
	azDenom = math.cos(math.radians(latitude)) * math.sin(math.radians(zenith))
	if abs(azDenom) > 0.001: 
		azRad = (( math.sin(math.radians(latitude)) * math.cos(math.radians(zenith)) ) - math.sin(math.radians(theta))) / azDenom
		if abs(azRad) > 1.0: 
			if azRad < 0.: 
				azRad = -1.0 
			else:
				azRad = 1.0
		
		azimuth = 180.0 - math.degrees(math.acos(azRad))
		if hourAngle > 0.0: 
			azimuth = -azimuth
	else:
		if latitude > 0.0: 
			azimuth = 180.0 
		else:
			azimuth = 0.0
	if azimuth < 0.0: 
		azimuth += 360.0
	exoatmElevation = 90.0 - zenith

	# Atmospheric Refraction correction
	if exoatmElevation > 85.0: 
		refractionCorrection = 0.0
	else:
		te = math.tan(math.radians(exoatmElevation))
		if exoatmElevation > 5.0: 
			refractionCorrection = 58.1 / te - 0.07 / (te*te*te) + 0.000086 / (te*te*te*te*te) 
		elif exoatmElevation > -0.575: 
			refractionCorrection = 1735.0 + exoatmElevation * (-518.2 + exoatmElevation * (103.4 + exoatmElevation * (-12.79 + exoatmElevation * 0.711) ) ) 
		else:
			refractionCorrection = -20.774 / te
		refractionCorrection = refractionCorrection / 3600.0

	solarZen = zenith - refractionCorrection
	
	return azimuth, solarZen


def calcSolNoonUTC( jd, longitude ):
	"""
Calculate time of solar noon the given day at the given location on earth (in minute since 0 UTC)
	"""
	tnoon = calcTimeJulianCent(jd)
	eqTime = calcEquationOfTime(tnoon)
	solNoonUTC = 720.0 - (longitude * 4.) - eqTime # in minutes
	return solNoonUTC


def calcSolNoon( jd, longitude, timezone, dst ):
	"""
Calculate time of solar noon the given day at the given location on earth (in minute)
	"""
	timeUTC    = calcSolNoonUTC(jd, longitude)
	newTimeUTC = calcSolNoonUTC(jd + timeUTC/1440.0, longitude)
	solNoonLocal = newTimeUTC + (timezone*60.0) # in minutes
	if dst: 
		solNoonLocal += 60.0
	return solNoonLocal


def calcSunRiseSetUTC( jd, latitude, longitude ):
	"""
Calculate sunrise/sunset the given day at the given location on earth (in minute since 0 UTC)
	"""
	t = calcTimeJulianCent(jd)
	eqTime = calcEquationOfTime(t)
	solarDec = calcSunDeclination(t)
	hourAngle = calcHourAngleSunrise(latitude, solarDec)
	# Rise time
	delta = longitude + math.degrees(hourAngle)
	riseTimeUTC = 720. - (4.0 * delta) - eqTime # in minutes
	# Set time
	hourAngle = -hourAngle
	delta = longitude + math.degrees(hourAngle)
	setTimeUTC = 720. - (4.0 * delta) - eqTime # in minutes
	return riseTimeUTC, setTimeUTC


def calcSunRiseSet( jd, latitude, longitude, timezone, dst ):
	"""
Calculate sunrise/sunset the given day at the given location on earth (in minutes)
	"""
	rtimeUTC, stimeUTC = calcSunRiseSetUTC(jd, latitude, longitude)
	# calculate local sunrise time (in minutes)
	rnewTimeUTC, snewTimeUTC = calcSunRiseSetUTC(jd + rtimeUTC/1440.0, latitude, longitude)
	rtimeLocal = rnewTimeUTC + (timezone * 60.0)
	rtimeLocal += 60.0 if dst else 0.0
	if rtimeLocal < 0.0 or rtimeLocal >= 1440.0: 
		jday = jd
		increment = 1. if rtimeLocal < 0. else -1.
		while rtimeLocal < 0.0 or rtimeLocal >= 1440.0:
			rtimeLocal += increment * 1440.0
			jday -= increment
	# calculate local sunset time (in minutes)
	rnewTimeUTC, snewTimeUTC = calcSunRiseSetUTC(jd + stimeUTC/1440.0, latitude, longitude)
	stimeLocal = snewTimeUTC + (timezone * 60.0)
	stimeLocal += 60.0 if dst else 0.0
	if stimeLocal < 0.0 or stimeLocal >= 1440.0: 
		jday = jd
		increment = 1. if stimeLocal < 0. else -1.
		while stimeLocal < 0.0 or stimeLocal >= 1440.0:
			stimeLocal += increment * 1440.0
			jday -= increment
	# return
	return rtimeLocal, stimeLocal


def calcTerminator( jd, latitudes, longitudes ):
	"""
Calculate terminator position and solar zenith angle for a given julian date-time within latitude/longitude limits
Note that for plotting only, basemap has a built-in terminator
	"""
	t = calcTimeJulianCent(jd)
	ut = ( jd - (int(jd - 0.5) + 0.5) )*1440.
	npoints = 100
	zen = zeros((npoints,npoints))
	lats = linspace(latitudes[0], latitudes[1], num=npoints)
	lons = linspace(longitudes[0], longitudes[1], num=npoints)
	for ilat in range(npoints):
		for ilon in range(npoints):
			az,el = calcAzEl(t, ut, lats[ilat], lons[ilon], 0.)
			zen[ilat,ilon] = el
	zmin = argmin(abs(90.-zen), axis=0)
	inds = (zmin != 0) & (zmin != len(zmin)-1)
	term = zeros((len(zmin[inds]),2))
	term[:,0] = lats[zmin[inds]]
	term[:,1] = lons[inds]
	return lats, lons, zen, term


def getJD( date ):
	"""
Calculate julian date for given day, month and year
	"""
	if date.month < 2: 
		date.year -= 1
		date.month += 12

	A = math.floor(date.year/100.)
	B = 2. - A + math.floor(A/4.)
	jd = math.floor(365.25*(date.year + 4716.)) + math.floor(30.6001*(date.month+1)) + date.day + B - 1524.5
	jd = jd + date.hour/24.0 + date.minute/1440.0 + date.second/86400.0
	return jd