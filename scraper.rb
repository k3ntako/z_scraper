require 'nokogiri'
require 'open-uri'
require 'date'
require 'json'

def scanNYC
  # northwest to southeast
  start_lat = 40.95
  end_lat = 40.50

  start_lng =  -74.1
  end_lng = -73.6

  lat_change = 0.015
  lng_change = 0.025

  lat = start_lat
  lng = start_lng

  now = DateTime.now
  now_str = now.strftime("W%AD%Y%m%dT%H%M%S%z")
  Dir.mkdir("./scraped/#{now_str}")


  while lat >= end_lat
    lng = start_lng
    while lng <= end_lng
      sleep(1)
      puts ("lat: #{lat}, lng: #{lng}")
      scraper( lat, lng, "16z", now_str )
      lng += lng_change
    end
    lat -= lat_change
  end
end

def scraper( lat, lng, zoom, run_time_str )
  # lat = 40.710171
  # lng = -74.007931
  # zoom = "16z"

  doc = Nokogiri::HTML(open("https://www.starbucks.com/store-locator?map=#{lat},#{lng},#{zoom}"))

  output = []

  script = doc.search('script').each do |content|
    if content.text.include? "window.__BOOTSTRAP ="
      output.push(content.text)
    end
  end

  regex = /window.__BOOTSTRAP = \{.*\}/

  matched = regex.match output[0]
  matched_str = matched.to_a.first
  matched_str = matched_str.gsub(/window.__BOOTSTRAP =(\s+)/, "")



  matched_hash = JSON.parse(matched_str)

  hash_locations = matched_hash["storeLocator"]["locationState"]["locations"]
  hash_coordinates = {
    lat: lat,
    lng: lng,
  }

  output_hash = {
    locations: hash_locations,
    coordinates: hash_coordinates,
    zoom: zoom,
    run_time_iso8601: run_time_str
  }


  File.write("./scraped/#{run_time_str}/#{lat}_#{lng}_#{zoom}.json", output_hash.to_json)
end

scanNYC
