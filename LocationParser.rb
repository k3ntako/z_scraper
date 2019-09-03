class LocationParser
  def day_of_week( file_path )
    puts "day_of_week"
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

  def get_business_hour( open_close_times )
    puts "get_business_hour"
    open_close_times_arr = open_close_times.split("to")
    open_time = self.parse_time open_close_times_arr[0]
    close_time = self.parse_time open_close_times_arr[1]



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

  def parse_time( timeStr )
    puts "parse_time"
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
end
