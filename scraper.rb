require 'nokogiri'
require 'open-uri'
require 'date'
require 'json'

def scraper(  )
  lat = 40.710171
  lng = -74.007931
  zoom = "15z"

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

  now = DateTime.now
  now_str = now.strftime("W%AD%Y%m%dT%H%M%S%z")

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
    run_time_iso8601: now_str
  }


  File.write("#{lat}_#{lng}_#{zoom}_#{now_str}.json", output_hash.to_json)
end

scraper
