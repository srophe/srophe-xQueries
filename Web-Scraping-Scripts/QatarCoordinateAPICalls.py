import requests
from bs4 import BeautifulSoup
import csv
import json
import re
import time

# The functions in this script are what is most useful. They can be passed a url that is used to call an API. This script was originally developed with the specific purpose of returning coordinates for records in the Beth Qatraye Gazetteer.
# The script may need to be adapted for future use. Please tag me on GitHub with @wlpotter if you have questions on using this script.
def PleiadesApiLookup(url):
    coordinates = ''
    if('http://' in url):
        url.replace('http://', 'https://')
    headers = {
    'User-Agent': 'Syriacabot/1.0',
    'From': 'william.potter@vanderbilt.edu'  # This is another valid field
    }
    pleiadesApiCall = url + '/json'
    response = requests.get(pleiadesApiCall, headers=headers)
    if(not response.json()['features']):
        coordinates = response.json()['reprPoint']
        return [str(coordinates[1]) + ' ' + str(coordinates[0]), "Pleiades: No features; using reprPoint"]
    if(response.json()['features'][0]['geometry'] is None):
        return ['', 'Plieades: No Coordinates Listed']
    pointPolygonOrLine = response.json()['features'][0]['geometry']['type']
    if(pointPolygonOrLine == 'Polygon' or pointPolygonOrLine == 'Line'):
        coordinates = response.json()['reprPoint']
    elif(pointPolygonOrLine == 'Point'):
        coordinates = response.json()['features'][0]['geometry']['coordinates']
    else:
        return ["Errror, check place", "Pleiades: Error"]
    return [str(coordinates[1]) + ' ' + str(coordinates[0]), "Pleiades: " + pointPolygonOrLine]

def DaInstApiLookup(url):
    daInstApiCall = url.replace('app/#!/show', 'place')+'.json'
    response = requests.get(daInstApiCall)
    if('prefLocation' in response.json()):
        coordinates = response.json()['prefLocation']['coordinates']
        return str(coordinates[1]) + ' ' + str(coordinates[0])
    else:
        return "DAINST: No Coordinates Listed"

def GeonamesApiLookup(url):
    if(re.search("/maps/google", url)):
        return "Error: no Geonames ID"
    geonameId = re.findall('[0-9]+', url)
    geonamesApiCall = 'http://api.geonames.org/getJSON?geonameId='+geonameId[0]+'&username=williamlpotter'
    response = requests.get(geonamesApiCall)
    lat = response.json()['lat']
    long = response.json()['lng']
    return lat + ' ' + long

def ViciApiLookup(url):
    viciApiCall = url.replace('vici/', 'object.php?id=')
    response = requests.get(viciApiCall)
    if('geometry' in response.json()):
        coordinates = response.json()['geometry']['coordinates']
        return str(coordinates[1]) + ' ' + str(coordinates[0])
    else:
        return "VICI: No Coordinates Listed"

def GoogleMapsLookup(url):
    session = requests.Session()
    unshortenedUrl = session.head(url, allow_redirects=True)
    regexMatch = re.compile("@(-?\d+\.\d+),(-?\d+\.\d+)")
    coordinates = regexMatch.findall(unshortenedUrl.url)[0]
    return coordinates[0] + ' ' + coordinates[1]


def CoordinateLookup(row):
    #use a switch statement to call an api lookup function based on how the lookup url appears
    #if matches dainst.org, look it up using that...
    if (row[2]!=''):
        #if there are already coordinates, return this message in the last column
        row[3] = "coordinates already extracted"
    elif (row[1]==''):
        #if there is no URI to lookup, return this message in the last column
        row[3] = "no coordinates to look up"
    elif (re.search("pleiades.stoa.org", row[1])):
        row[2], row[3] = PleiadesApiLookup(row[1])
    #pleiades
    elif (re.search("gazetteer.dainst.org", row[1])):
        row[2] = DaInstApiLookup(row[1])
        row[3] = "dainst"
    elif (re.search("geonames.org", row[1])):
        row[2] = GeonamesApiLookup(row[1])
        row[3] = "Geonames"
    elif (re.search("goo.gl/maps/", row[1])):
        row[2] = GoogleMapsLookup(row[1])
        row[3] = "Google short URl"
    elif (re.search("vici.org", row[1])):
        row[2] = ViciApiLookup(row[1])
        row[3] = "Vici"
    else:
        row[3] = "Please check. Something seems wrong..."
    return row

inFile = '/Users/dhlab/Documents/GitHub/bethqatraye-preprocessing-scripts/apiInput.csv'
with open(inFile, 'r') as csvfile:
    reader = csv.reader(csvfile, delimiter='\t', quotechar="'")
    with open('apiOutput.csv', 'w') as outputFile:
        writer = csv.writer(outputFile, delimiter='\t')
        for row in reader:
            newRow = CoordinateLookup(row) #passes row to a function that tries to grab coordinates; if it can't, it passes back an error as the 4th row. This function returns four values to the newRow which gets written into the output file.
            writer.writerow(newRow)
            time.sleep(3)


#print(PleiadesApiLookup('https://pleiades.stoa.org/places/579885'))
#print(GeonamesApiLookup('http://sws.geonames.org/107744'))
#print(DaInstApiLookup('https://gazetteer.dainst.org/app/#!/show/2042645'))
