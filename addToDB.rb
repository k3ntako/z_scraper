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

class ParseFileToDB < IterateThroughFiles
  def initialize
    self.start
  end

  def manage_location( new_location_params )
    Location.new(new_location_params).save!
    File.write("./scraped/ran.txt", @current_folder_name, mode: "a")
  end
end

parse = ParseFileToDB.new

ActiveRecord::Base.connection.close
