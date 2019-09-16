require_relative './CreateNewLocation'

class IterateThroughFiles < CreateNewLocation
  def start
    chain = Chain.find_by(name: "Starbucks")
    if !chain
      chain = Chain.create(name: "Starbucks")
    end

    @chain_id = chain.id

    files_ran = File.open("./scraped/ran.txt")
    @files_ran_arr = files_ran.readlines.map(&:chomp)

    iterate_through_folders
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
      iterate_through_locations( file_path )
    end
  end

  def iterate_through_locations( file_path )
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


      if existing_location.length > 0
        puts "skipped #{location_hash["storeNumber"]}"
        next
      end

      puts location_hash["storeNumber"]

      new_location_params = self.create_new_location(file_path, location_hash, @chain_id)
      next if !new_location_params
      self.manage_location( new_location_params )
    end
  end
end
