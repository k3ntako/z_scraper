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
    folders = Dir["./scraped/*/"]

    folders.each do |folder_path|
      @current_folder_name = folder_path.split("./scraped/").last.split("/").first
      next if @files_ran_arr.include? @current_folder_name

      self.iterate_through_files(folder_path)
    end
  end

  def iterate_through_files(folder_path)
    file_paths = Dir["#{folder_path}*.json"]
    file_paths.each do |file_path|
      parse_location( file_path )
    end
  end

  def parse_location( file_path )
    str = File.read(file_path)
    hash = JSON.parse(str)
    hash["locations"].each do |location_hash|
      address_hash = location_hash["address"]
      query_string = "address->>'address_part_1' = ? AND address->>'zipcode' = ? AND address->>'country' = ?"
      existing_location = Location.where(
        query_string,
        address_hash["streetAddressLine1"],
        address_hash["postalCode"],
        address_hash["countryCode"],
      )

      next if existing_location.length > 0

      new_location = Location.new

      new_location.chain_id = @chain_id

      new_location.name = location_hash["name"]
      new_location.lat = location_hash["coordinates"]["latitude"]
      new_location.lng = location_hash["coordinates"]["longitude"]
      new_location.address = {
        address_part_1: address_hash["streetAddressLine1"],
        address_part_2: address_hash["streetAddressLine2"],
        address_part_3: address_hash["streetAddressLine3"],
        city: address_hash["city"],
        state: address_hash["countrySubdivisionCode"],
        zipcode: address_hash["postalCode"].to_s[0..4], #first five characters
        country: address_hash["countryCode"],
      }

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

      new_location.save!
    end
    File.write("./scraped/ran.txt", @current_folder_name, mode: "a")
  end
end

parse = ParseFileToDB.new
parse.iterate_through_folders

ActiveRecord::Base.connection.close
