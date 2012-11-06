# iOS Wunderground Barometer Test

--

On Stack Overflow a user asked [how to receive atmospheric pressure from a weather service](http://stackoverflow.com/questions/13215798/how-to-receive-atmospheric-pressure-from-a-weather-service-and-display-in-a-ipho/13226614#13226614). There are various services that can do this, but the basic model is the same:

1. Using `CoreLocation.framework` to determine a device's location;
2. Establishing a connection to web-based weather service to retrieve weather information (JSON or XML would be common formats);
3. Parsing the response output; and
4. Updating the iOS app user interface with the barometer information.

So, this project illustrates an example of how this might be done. This particular demonstration is retrieving data in JSON format from www.wunderground.com (a sample weather API referenced to in the [The Weather Channel's services](http://www.weather.com/services/) page). But the basic structure would be similar when retrieving weather information from other services, too (though the details of how the URL is constructed, how the JSON is parsed, etc., will vary, obviously).

Note, this assumes that you have a Wunderground "key id" for your app by visiting http://www.wunderground.com/weather/api/?ref=twc

--

If you have any questions, do not hesitate to contact me at 

Rob Ryan
robert.ryan@mindspring.com

6 November 2012

