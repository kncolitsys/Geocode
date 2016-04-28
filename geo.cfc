<!---
This geocode component is based off of John Blayter Geo.cfc and Ray Ramden's Google Geocode Component
--->
<cfcomponent output="no">
	<cffunction name="Geocode" access="remote" returntype="any" hint="sends data to google, and returns lat/lng,accuracy,status">
		<cfargument name="fullAddress"	type="string"	required="false" default=""  hint="full address string bypassing the additional address structure">
		<cfargument name="address1"	    type="string"	required="false" default=""  hint="street address line 1">
		<cfargument name="address2"	    type="string"	required="false" default=""  hint="street address line 2">
		<cfargument name="city"			type="string"	required="false" default=""  hint="city">
		<cfargument name="state"		type="string"	required="false" default=""  hint="state">
		<cfargument name="postalCode"	type="string"	required="false" default=""  hint="postal code">
		<cfargument name="countryCode"	type="string"	required="false" default=""  hint="the country code that we use to look up the states for">
		<cfargument name="googleMapKey" type="string"	required="false" default=""  hint="your google map key for your site">
		<cfargument name="attempt"		type="numeric"	required="false" default="0" hint="number of times we've tried to geocode">
		<cfscript>
			var instance = structNew();

				if(len(arguments.fullAddress)) {
					instance.addressString = trim(arguments.fulladdress);
				}
				else {
					arguments.attempt++;
					switch(arguments.attempt) {
						case 1:
							instance.addressString = arguments.address1 & arguments.address2 & ',' & arguments.city & ',' & arguments.state & arguments.postalCode & arguments.countryCode;
						break;
						case 2:
							instance.addressString = arguments.address1 & ',' & arguments.City & ',' & arguments.State & arguments.postalCode & arguments.countryCode;
						break;
						case 3:
							instance.addressString = arguments.address1 & ',' & arguments.City & ',' & arguments.State & arguments.countryCode;
						break;
						case 4:
							instance.addressString = arguments.City & ',' & arguments.State & arguments.countryCode;
						break;
						case 5:
							instance.addressString = arguments.City & ',' & arguments.countryCode;
						break;
						default:
							instance.addressString = arguments.countryCode;
						break;
					}
				}
				
				instance.checkGeoCache = checkGeocodeCache(instance.addressString);
				
				if(instance.checkGeoCache.hasGeocode eq true) {
					return instance.checkGeoCache;
				}
				else {

					instance.XmlFile = googleGeocodeHttpRequest(googleMapAPIKey:arguments.googleMapKey,addressString:replace(instance.addressString,' ','+','all'));
					instance.statusCode = instance.xmlFile.kml.response.status.code.XmlText;
					instance.sReturn = structNew();

					switch(instance.statusCode) {
						case 602:
							if(arguments.attempt lte 6 && arguments.attempt neq 0) {
								arguments.attempt++;
								Geocode(argumentCollection=arguments);
							}
							else {
								instance.sReturn.hasGeocode		= false;
								instance.sReturn.statusString	= translateStatuscode(statusCode:instance.statusCode);
							}
						break;
	
						case 200:
							instance.sReturn.hasGeocode		= true;
							instance.sReturn.statusString	= translateStatuscode(statusCode:instance.statusCode);
							instance.sReturn.Lon			= listGetAt(instance.xmlFile.kml.response.placemark.point.coordinates.XmlText,1);
							instance.sReturn.Lat			= listGetAt(instance.xmlFile.kml.response.placemark.point.coordinates.XmlText,2);
							instance.sReturn.Accuracy		= instance.xmlFile.kml.Response.Placemark.AddressDetails.XmlAttributes.Accuracy;
							instance.sReturn.retAddress		= instance.xmlFile.kml.response.placemark.address.XmlText;

							addGeocodeCache(
											address:instance.xmlFile.kml.response.placemark.address.XmlText,
											accuracy:instance.sReturn.Accuracy,
											lon:instance.sReturn.Lon,
											lat:instance.sReturn.Lat
											);

						break;

						default:
							instance.sReturn.hasGeocode		= false;
							instance.sReturn.statusString	= translateStatuscode(statusCode:instance.statusCode);
						break;
					}
					return instance.sReturn;
				}
		</cfscript>
	</cffunction>

	<cffunction name="translateStatuscode" access="private" output="false" returnType="string" hint="Translates a status code to a string.">
		<cfargument name="statusCode" type="numeric" required="true">
		<!--- Based on http://www.google.com/apis/maps/documentation/reference.html#GGeoStatusCode --->
		<cfscript>
		switch(arguments.statusCode) {
			case 200:
				return 'No errors occurred; the address was successfully parsed and its geocode has been returned.';
			break;
			case 500:
				return 'A geocoding request could not be successfully processed, yet the exact reason for the failure is not known.';
			break;
			case 601:
				return 'The HTTP q parameter was either missing or had no value.';
			break;
			case 602:
				return 'No corresponding geographic location could be found for the specified address. This may be due to the fact that the address is relatively new, or it may be incorrect.';
			break;
			case 603:
				return 'The geocode for the given address cannot be returned due to legal or contractual reasons.';
			break;
			case 610:
				return 'The given key is either invalid or does not match the domain for which it was given.';
			break;
			default:
				return 'Unknown value';
			break;
		}
		</cfscript>
	</cffunction>

	<cffunction name="googleGeocodeHttpRequest" access="private" returntype="xml">
		<cfargument name="googleMapAPIKey" required="yes" type="string">
		<cfargument name="addressString" required="yes" type="string">
		<cfset var googleGeocodeHttpRequestReturn = '' />
			<cfhttp
				method="get"
				url="http://maps.google.com/maps/geo?q=#URLEncodedFormat(arguments.addressString)#&output=xml&key=#arguments.googleMapAPIKey#"
				resolveurl="no"
				result="googleGeocodeHttpRequestReturn">
			</cfhttp>
		<cfreturn XmlParse(googleGeocodeHttpRequestReturn.FileContent) />
	</cffunction>

	<cffunction name="addGeocodeCache" access="private" returntype="void">
		<cfargument name="address" type="string" default="" hint="Full Address to add cache">
		<cfargument name="accuracy" type="numeric" default="0" hint="Accuracy of geocode">
		<cfargument name="lon" type="numeric" default="0" hint="Latitude of geocode">
		<cfargument name="lat" type="numeric" default="0" hint="Longitude of geocode">
		<cfset var addGeocodeCacheQuery = "" />
		<cfset var addGeocodeCacheCheckQuery = "" />
		
			<CFQUERY NAME="addGeocodeCacheCheckQuery" DATASOURCE="simplegeocode">
				SELECT fulladdress FROM geocodecache
				WHERE fulladdress = <cfqueryparam value="#arguments.address#" cfsqltype="cf_sql_varchar">
			</CFQUERY>
			
			<cfif addGeocodeCacheCheckQuery.RecordCount eq 0>
				<CFQUERY NAME="addGeocodeCacheQuery" DATASOURCE="simplegeocode">
					INSERT INTO geocodecache
						(fulladdress,accuracy,latitude,longitude)
					VALUES
						(
						<cfqueryparam value="#arguments.address#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#arguments.accuracy#" cfsqltype="cf_sql_bigint">,
						<cfqueryparam value="#arguments.lat#" cfsqltype="cf_sql_float">,
						<cfqueryparam value="#arguments.lon#" cfsqltype="cf_sql_float">
						)
				</CFQUERY>
			</cfif>

	</cffunction>

	<cffunction name="checkGeocodeCache" access="private" returntype="struct">
		<cfargument name="address" type="string" default="" hint="Full Address to check from cache">
		<cfset var checkGeocodeCacheQuery = "" />
		<cfset var checkGeocodeCacheReturn = StructNew() />
			<CFQUERY NAME="checkGeocodeCacheQuery" DATASOURCE="simplegeocode">
				SELECT accuracy,latitude,longitude,fulladdress
				FROM geocodecache
				WHERE fullAddress = <cfqueryparam value="#arguments.address#" cfsqltype="cf_sql_varchar">
				LIMIT 1;
			</CFQUERY>
			<cfscript>
				if(checkGeocodeCacheQuery.RecordCount gt 0) {
					checkGeocodeCacheReturn.hasGeocode=true;
				}
				else {
					checkGeocodeCacheReturn.hasGeocode=false;
				}
				checkGeocodeCacheReturn.Lat=checkGeocodeCacheQuery.latitude;
				checkGeocodeCacheReturn.Lon=checkGeocodeCacheQuery.longitude;
				checkGeocodeCacheReturn.Accuracy=checkGeocodeCacheQuery.accuracy;
				checkGeocodeCacheReturn.statusString=translateStatuscode(200);
				checkGeocodeCacheReturn.retAddress=checkGeocodeCacheQuery..fulladdress;
				return checkGeocodeCacheReturn;
			</cfscript>
	</cffunction>

</cfcomponent>