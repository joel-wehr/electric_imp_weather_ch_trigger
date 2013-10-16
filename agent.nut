//**************************Weather Channel*************************************
// Weather Channel Trigger Agent
// Uses Wunderground API to obtain current time and sunrise/sunset information
// for use in triggering events.
// Modified from code available at the Electric Imp GitHub page.

server.log("Weather Agent Running");

// Add your own wunderground API Key here. 
// Register for free at http://api.wunderground.com/weather/api/
local myAPIKey = "YOUR API KEY GOES HERE";
local wunderBaseURL = "http://api.wunderground.com/api/"+myAPIKey+"/";

// Add the zip code you want to get information for here.
local zip = "YOUR ZIP CODE GOES HERE";

// The wunderground API has a lot of different features (tides, sailing, etc)
// We use "astronomy" to indicate we want the information available for solar
// and lunar events.
local reportType = "astronomy";

// These functions send commands to the device. Modify accordingly
function switchOff() {
    server.log("Sunrise. Switch off")
    device.send("off", "");
    getConditions();
}
function switchOn() {
    server.log("Sunset. Switch on.")
    device.send("on", "");
    getConditions();
}

function getConditions() {
    server.log(format("Agent getting current conditions for %s", zip));
    
    // cat some strings together to build our request URL
    local reqURL = wunderBaseURL+reportType+"/q/"+zip+".json";

    // call http.get on our new URL to get an HttpRequest object. Note: we're not using any headers
    server.log(format("Sending request to %s", reqURL));
    local req = http.get(reqURL);

    // send the request synchronously (blocking). Returns an HttpMessage object.
    local res = req.sendsync();

    // check the status code on the response to verify that it's what we actually wanted.
    server.log(format("Response returned with status %d", res.statuscode));
    if (res.statuscode != 200) {
        server.log("Request for Weather Channel API data failed.");
        imp.wakeup(600, getConditions);
        return;
    }
    // hand off data to be parsed
    local response = http.jsondecode(res.body); 
    // load table "astronomy" with the moon_phase JSON data
    local astronomy = response.moon_phase;
    // get and format Sunrise time string
    local sunrise = "";
    sunrise += (astronomy.sunrise.hour + ":" + astronomy.sunrise.minute);
    server.log("Sunrise: " + sunrise);
    // get and format Sunset time string
    local sunset = "";
    sunset += (astronomy.sunset.hour + ":" + astronomy.sunset.minute);
    server.log("Sunset: " + sunset);
    // Get and convert the current time to minutes since zero hour.
    server.log("Current time: " + astronomy.current_time.hour + ":" + astronomy.current_time.minute);
    local mszh = (astronomy.current_time.hour.tointeger() * 60) + (astronomy.current_time.minute.tointeger());
    server.log("Minutes since zero hour: " + mszh);
    // convert sunset to minutes
    local sunsetmin = (astronomy.sunset.hour.tointeger() * 60) + (astronomy.sunset.minute.tointeger());
    server.log("Sunset in Minutes: " + sunsetmin);
    // convert sunrise to minutes
    local sunrisemin = (astronomy.sunrise.hour.tointeger() * 60) + (astronomy.sunrise.minute.tointeger());
    server.log("Sunrise in Minutes: " + sunrisemin);
    // conversion done in minutes...
    local min_till = 0;
    // ...but imp.wakeup takes seconds so we will convert for that as well.
    local sec_till = 0;
    //if the current time is prior to sunrise that day
    if (mszh <= sunrisemin && mszh < sunsetmin) { 
        min_till = sunrisemin - mszh;
        server.log(min_till + " minutes until sunrise.");
        // in case min_till is 0, we add 1. 
        min_till = min_till + 1;
        sec_till = min_till * 60
        imp.wakeup(sec_till, switchOff); //Turn off switch
    }
    //if the current time is after sunrise and before sunset
    else if (mszh > sunrisemin && mszh <= sunsetmin) { 
        min_till = sunsetmin - mszh;
        server.log(min_till + " minutes until sunset.")
        min_till = min_till + 1;
        sec_till = min_till * 60
        imp.wakeup(sec_till, switchOn); //Turn on switch
    }
    //if the current time is after sunset, we set a trigger to update tommorrow
    else {
        min_till = (1440 - mszh);
        server.log(min_till + " minutes until 2400 hours.")
        min_till = min_till + 1;
        sec_till = min_till * 60
        imp.wakeup(sec_till, getConditions); 
    }
}
getConditions();

//*************************End Weather Channel**********************************
