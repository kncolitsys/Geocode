<cfset GoogleMapAPIKey = "ABQIAAAAgOXkzAhHanTHqJAN6Nyd5xTTSeL2BSh5KZoGEPeCzFhfWzK6zxRNRXx3pARj7OIC26bl37OYaD8IVg">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Simple Geocode</title>

<cfajaxproxy cfc="geo" jsclassname="GeoProxy">

<script>
function initializeMap(mapAreaID) {
	if(GBrowserIsCompatible()) {
        map = new GMap2(document.getElementById(mapAreaID));
		map.addControl(new GLargeMapControl());
		map.addControl(new GMapTypeControl());
		map.setCenter(new GLatLng('37.40047','-122.072981'),9);
	}
}
function doGetGeocode(fullAddress) {
	if(fullAddress!='') {
		var jsDoGetGeocode = new GeoProxy();
			jsDoGetGeocode.setCallbackHandler(showGetGeocode);
			jsDoGetGeocode.Geocode(fullAddress);
	}
}

function showGetGeocode(geocodeObj) {
	if(!geocodeObj.HASGEOCODE) {
		alert(geocodeObj.STATUSSTRING);
	}
	else {
		map.panTo(new GLatLng(geocodeObj.LAT,geocodeObj.LON));
		document.getElementById('showStatus').innerHTML=geocodeObj.STATUSSTRING;
		document.getElementById('showLat').innerHTML=geocodeObj.LAT;
		document.getElementById('showLon').innerHTML=geocodeObj.LON;
		document.getElementById('showAccuracy').innerHTML=geocodeObj.ACCURACY;
		document.getElementById('showRetaddress').innerHTML=geocodeObj.RETADDRESS;
	}
}
</script>

<cfoutput>
<script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=#GoogleMapAPIKey#" type="text/javascript"></script>
</cfoutput>
</head>

<body onload="initializeMap('MapArea');" onunload="GUnload();">

<div id="MapArea" style="height:400px; width:600px; overflow:visible;" class="tah12">
</div>

<br />
<form id="geocodeForm">
	Address: <input type="text" name="fullAddress" id="fullAddress" />
	<br />
	<input type="button" name="geocode" id="geocode" value="Geocode" onclick="doGetGeocode(this.form.fullAddress.value);" />
</form>

<br />

<div><strong>Status String:</strong> <span id="showStatus"></span> </div>

<div><strong>Latitude:</strong> <span id="showLat"></span> </div>

<div><strong>Longitude:</strong> <span id="showLon"></span> </div>

<div><strong>Accuracy:</strong> <span id="showAccuracy"></span> </div>

<div><strong>Returned Address:</strong> <span id="showRetaddress"></span> </div>

</body>
</html>
