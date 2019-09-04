require 'json'
require 'pg'
require 'pg_search'
require 'active_record'
require 'date'
require '../CafeTako/app/models/application_record'
require '../CafeTako/app/models/location'
require '../CafeTako/app/models/chain'
require '../CafeTako/app/models/business_hour'
require_relative './IterateThroughFiles'


ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'CafeTako_development'
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

    location_line = "\n+#{lp["name"]}+#{address_json}+#{lp["lat"]}+#{lp["lng"]}"
    puts location_line
    File.write("./scraped/csv/WITH_DUPLICATES_output_#{@now_str}.csv", location_line, mode: "a")
  end
end

now = DateTime.now
now_str = now.strftime("W%AD%Y%m%dT%H%M%S%z")
ConvertToCSV.new( now_str )

# removes duplicates
system("sort -u ./scraped/csv/WITH_DUPLICATES_output_#{now_str}.csv > ./scraped/csv/output_#{now_str}.csv")
# adds new line at the top
system("sed -i.bu '1i\\
id+name+address+lat+lng' ./scraped/csv/output_#{now_str}.csv")
puts "Completed"


ActiveRecord::Base.connection.close
