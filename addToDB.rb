require 'json'
require 'pg'
require 'pg_search'
require 'active_record'
require 'date'
require '../CafeTako/app/models/application_record'
require '../CafeTako/app/models/location'
require '../CafeTako/app/models/chain'
require '../CafeTako/app/models/business_hour'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'CafeTako_development'
)

def iterateThroughFiles
  chain = Chain.find_by(name: "Starbucks")
  if !chain
    chain = Chain.create(name: "Starbucks")
  end

  chain_id = chain.id
  paths = Dir["./scraped/*.json"]
  paths.each do |file_path|
    addToDB( file_path, chain_id )
  end
end

def parseTime( timeStr )
  timeString = timeStr.strip
  timeArr = timeString.split(" ")
  hour_and_min = timeArr[0].split(":")

  hour = hour = hour_and_min[0].to_i * 60
  min = hour_and_min[1].to_i

  if hour_and_min[0].to_i == 12 && timeArr[1].downcase.include?( "am" )
    hour = 0
  elsif timeArr[1].downcase.include?( "pm" ) && hour_and_min[0].to_i != 12
    hour += 12 * 60
  end

  hour + min
end

def createBusinessHour(open_time, close_time)
  bh = BusinessHour.find_by open_time: open_time, close_time: close_time

  if bh
    return bh.id
  end

  new_bh = BusinessHour.new
  new_bh.open_time = open_time
  new_bh.close_time = close_time
  new_bh.save!
  new_bh.id
end

def day_of_week( file_path )
  tomorrow = {
    "Sunday" => "Monday",
    "Monday" => "Tuesday",
    "Tuesday" => "Wednesday",
    "Wednesday" => "Thursday",
    "Thursday" => "Friday",
    "Friday" => "Saturday",
    "Saturday" => "Sunday"
  }

  date_str = file_path.split("W").last.split("D").first
  [date_str, tomorrow[date_str]]
end

def addToDB( file_path, chain_id )
  str = File.read(file_path)
  hash = JSON.parse(str)
  hash["locations"].each do |location_hash|
    address = location_hash["addressLines"].join(" ")
    existing_location = Location.where("name = ? OR address = ?", location_hash["name"], address)

    next if existing_location.length > 0

    puts "-----"
    puts location_hash.inspect

    new_location = Location.new

    new_location.chain_id = chain_id

    new_location.name = location_hash["name"]
    new_location.lat = location_hash["coordinates"]["latitude"]
    new_location.lng = location_hash["coordinates"]["longitude"]
    new_location.address = address

    business_hours = {}
    today_tomorrow = day_of_week( file_path )

    next if !location_hash["schedule"]
    location_hash["schedule"].each do | day_hash |

      if day_hash["open"]
        hours = day_hash["hours"].split("to")
        open_time = parseTime hours[0]
        close_time = parseTime hours[1]

        dayName = day_hash["dayName"].strip.capitalize
        if dayName == "Today"
          dayName = today_tomorrow[0]
        elsif dayName == "Tomorrow"
          dayName = today_tomorrow[1]
        end

        bh_id = createBusinessHour(open_time, close_time)
        business_hours[dayName] = bh_id
      else
        business_hours[dayName] = nil
      end
    end
    new_location.business_hours = business_hours

    puts new_location.inspect
    new_location.save!
    # puts location_hash["features"]
    # puts location_hash["slug"]
  end
end

iterateThroughFiles
