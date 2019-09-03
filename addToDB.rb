require 'json'
require 'pg'
require 'pg_search'
require 'active_record'
require 'date'
require '../CafeTako/app/models/application_record'
require '../CafeTako/app/models/location'
require '../CafeTako/app/models/chain'
require '../CafeTako/app/models/business_hour'
require_relative './LocationParser'


ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'CafeTako_development'
)

class ParseFileToDB < LocationParser
  def initialize
    chain = Chain.find_by(name: "Starbucks")
    if !chain
      chain = Chain.create(name: "Starbucks")
    end

    @chain_id = chain.id

    files_ran = File.open("./scraped/ran.txt")
    @files_ran_arr = files_ran.readlines.map(&:chomp)
  end

  def iterate_through_folders
    puts "iterate_through_folders"
    folders = Dir["./scraped/*/"]

    folders.each do |folder_path|
      @current_folder_name = folder_path.split("./scraped/").last.split("/").first
      next if @files_ran_arr.include? @current_folder_name

      self.iterate_through_files(folder_path)
    end
  end

  def iterate_through_files(folder_path)
    puts "iterate_through_files"
    file_paths = Dir["#{folder_path}*.json"]
    file_paths.each do |file_path|
      parse_location( file_path )
    end
  end

  def parse_location( file_path )
    puts "parse_location"
    str = File.read(file_path)
    hash = JSON.parse(str)
    hash["locations"].each do |location_hash|
      address = location_hash["addressLines"].join(" ")
      existing_location = Location.where("name = ? OR address = ?", location_hash["name"], address)

      next if existing_location.length > 0

      puts "-----"
      puts location_hash.inspect

      new_location = Location.new

      new_location.chain_id = @chain_id

      new_location.name = location_hash["name"]
      new_location.lat = location_hash["coordinates"]["latitude"]
      new_location.lng = location_hash["coordinates"]["longitude"]
      new_location.address = address

      business_hours = {}
      today_tomorrow = self.day_of_week( file_path )

      next if !location_hash["schedule"]
      location_hash["schedule"].each do | day_hash |

        if day_hash["open"]
          dayName = day_hash["dayName"].strip.capitalize
          if dayName == "Today"
            dayName = today_tomorrow[0]
          elsif dayName == "Tomorrow"
            dayName = today_tomorrow[1]
          end

          bh_id = self.get_business_hour( day_hash["hours"] )
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
    File.write("./scraped/ran.txt", @current_folder_name, mode: "a")
  end
end

parse = ParseFileToDB.new
parse.iterate_through_folders

ActiveRecord::Base.connection.close
