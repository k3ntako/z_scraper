require 'json'
require 'pg'
require 'pg_search'
require 'active_record'
require 'date'
require '../CafeTako/app/models/application_record'
require '../CafeTako/app/models/location'
require '../CafeTako/app/models/chain'
require '../CafeTako/app/models/business_hour'
require './config'
require_relative './IterateThroughFiles'

config = Config.new

ActiveRecord::Base.establish_connection(
  :adapter  => config.adapter,
  :host     => config.host,
  :username => config.username,
  :password => config.password,
  :database => config.database
)

class ConvertToCSV < IterateThroughFiles
  def initialize( now_str )
    @now_str = now_str
    self.start
  end

  def manage_location( new_location_params )
    lp = new_location_params
    address_json = lp["address"].to_s.gsub(":", "")
    address_json = address_json.gsub("=>", ":")
    address_json = address_json.gsub("nil", "null")

    location_line = "\n+#{lp["name"]}+#{address_json}+#{lp["lat"]}+#{lp["lng"]}+#{lp["business_hours"]}"
    puts location_line
    File.write("./csv/WITH_DUPLICATES_output_#{@now_str}.csv", location_line, mode: "a")
  end

  def get_business_hour( open_close_times )
    open_close_times_arr = open_close_times.split("to")
    open_time = self.parse_time open_close_times_arr[0]
    close_time = self.parse_time open_close_times_arr[1]

    {
      "open_time" => open_time,
      "close_time" => close_time,
      "is_open" => true,
    }
  end
end

now = DateTime.now
now_str = now.strftime("W%AD%Y%m%dT%H%M%S%z")
ConvertToCSV.new( now_str )

# removes duplicates
system("sort -u ./csv/WITH_DUPLICATES_output_#{now_str}.csv > ./csv/output_#{now_str}.csv")
# adds new line at the top
# system("sed -i.bu '1i\\
# id+name+address+lat+lng+business_hours' ./csv/output_#{now_str}.csv")
puts "Completed"


ActiveRecord::Base.connection.close
