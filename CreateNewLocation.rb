require_relative './LocationParser'

class CreateNewLocation < LocationParser
  def create_new_location( file_path, location_hash, chain_id )
    address_hash = location_hash["address"]
    new_location = {
      "chain_id" => chain_id,
      "name" => location_hash["name"],
      "lat" => location_hash["coordinates"]["latitude"],
      "lng" => location_hash["coordinates"]["longitude"],
      "address" => {
        "address_part_1" => address_hash["streetAddressLine1"],
        "address_part_2" => address_hash["streetAddressLine2"],
        "address_part_3" => address_hash["streetAddressLine3"],
        "city" => address_hash["city"],
        "state" => address_hash["countrySubdivisionCode"],
        "zipcode" => address_hash["postalCode"].to_s[0..4], #first five characters
        "country" => address_hash["countryCode"],
      }
    }

    business_hours = {}
    today_tomorrow = self.day_of_week( file_path )

    return nil if !location_hash["schedule"]
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
    new_location["business_hours"] = business_hours

    return new_location
  end
end
