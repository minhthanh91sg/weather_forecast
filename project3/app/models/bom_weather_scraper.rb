require 'nokogiri'
require 'open-uri'
require 'openssl'
require 'json'
require 'date'
require 'nokogiri'
require 'csv'

# scrape URLs
BOM_BASE_URL = 'http://www.bom.gov.au'
BOM_OBSERVATION_URL = '/vic/observations/vicall.shtml'

# Control what debug messages to print.
INFO = true
DEBUG = true
TRACE = true

class BomWeatherScraper < Scraper
    def scrape()
		if(INFO) then puts("Starting BOM Scraper") end
	    vic_all_url = BOM_BASE_URL + BOM_OBSERVATION_URL
		if(DEBUG) then puts("Getting all location names and URLs from BOM, Source URL: #{vic_all_url}") end
		
		# Open the HTML link with Nokogiri
		vic_all_page = Nokogiri::HTML(open(vic_all_url))
		 
		vic_all_page.css('table').each do |table|
		    tbody = table.at_css('tbody')
			tbody.css('tr').each do |tr|
				# get the heading which contains the name
				# and link to the specific page
				heading = tbody.at_css('th')
				area_details_url = heading.css('a').attribute('href')
				area_name = heading.css('a').text
				area_name = normalise_name(area_name)
			
				#debug
				if(TRACE) then puts("Area URL:" + area_details_url) end
				if(TRACE) then puts("Area Name:" +area_name) end
				
				# scrape data out of details page
				scrape_area(area_details_url)
			end
		end
		 
		if(INFO) then puts("BOM Scraper finished") end
    end
	
	def scrape_area(area_details_url)
		if(DEBUG) then puts("Opening area details page: " + area_details_url) end
		area_details_page = Nokogiri::HTML(open(BOM_BASE_URL + area_details_url))
		
		json_link = area_details_page.search('a').
		select { |a| !a.nil? }.
		map { |a| a.attribute('href') }.
		select { |href| !href.nil? }.
		map { |href| href.text }.
		select { |link| link.start_with?('/fwo/') }.
		select { |link| link.end_with?('.json') }[0]
		
		current_station_record = nil
		
		if(!json_link.nil?)
			# open json for area details
			if(DEBUG) then puts("Opening area details json: " + json_link) end
			area_details_json = JSON.parse(open(BOM_BASE_URL + json_link).read)
			
			# parse all the info out of the json
			all_data = area_details_json['observations']['data'].reverse # reverse to get the times in ascending order
			
			last_station_name_added = nil
			
			
			last_rainfall_reading_since_9am_mm = nil
			second_last_rainfall_reading_since_9am_mm = nil
			
			all_data.each do |data_set|
				# pull the data out of this set
				area_name = normalise_name(data_set['name'])
				lat = data_set['lat'].to_f
				lon = data_set['lon'].to_f
				
				#Check if the area is created, and if not,
				#Create the area in the database with area_name, lat and lon
				
				# check if we've already checked this before
				# gives huge performance gain
				if(area_name != last_station_name_added)
					if(TRACE) then puts("Changing Station to #{area_name}") end
					station = Station.where({ name: area_name })[0]
					
					if(station.nil?)
						if(DEBUG) then puts("Creating station: " + area_name) end
						# station does not exist, create it now
						station = Station.new
						station.name = area_name
						station.lat = lat
						station.long = lon
						
						station.save					
					else
						if(TRACE) then puts("Station #{area_name} already exists") end
					end
					
					# track the current station record so we don't need to keep finding it
					current_station_record = station
					last_station_name_added = area_name
					
					# reset rainfall cache since we're now on a new station
					last_rainfall_reading_since_9am_mm = nil
					second_last_rainfall_reading_since_9am_mm = nil
				end
				
				read_datetime = DateTime.parse(data_set['local_date_time_full'])
				temperature = data_set['air_temp'].to_f
				wind_speed_kph = data_set['wind_spd_kmh'].to_f
				wind_angle = bearing_to_angle(data_set['wind_dir'])
				rain_since_9am_mm = data_set['rain_trace'].to_f
				
				if(TRACE) then puts("Read Time: " + read_datetime.to_s) end
				if(TRACE) then puts("Area Name: " + area_name) end
				if(TRACE) then puts("Latitude: #{lat.to_s} Longitude: #{lon.to_s}") end
				if(TRACE) then puts("Temperature: " + temperature.to_s) end
				if(TRACE) then puts("Wind Speed: " + wind_speed_kph.to_s) end
				if(TRACE) then puts("Wind Angle: " + wind_angle.to_s) end
				if(TRACE) then puts("Rain since 9am mm: " + rain_since_9am_mm.to_s) end
				
				# find rain this hour.
				# sort all weather readings by time, latest at the top
				# find first one that is one hour ago within tolerance
				# and then subtract
				rain_last_hour_mm = nil;
				
				# since we have readings every 30 mins, track the last and the second last reading
				# so we can determine rain in the last hour by subtracting from second last reading.
				
				if(second_last_rainfall_reading_since_9am_mm.nil?)
					if(last_rainfall_reading_since_9am_mm.nil?)
						rain_last_hour_mm = rain_since_9am_mm
					else 
						rain_last_hour_mm = rain_since_9am_mm - last_rainfall_reading_since_9am_mm
					end
				elsif
					rain_last_hour_mm = rain_since_9am_mm - second_last_rainfall_reading_since_9am_mm
				end
				
				# shuffle rainfall cache down
				second_last_rainfall_reading_since_9am_mm = last_rainfall_reading_since_9am_mm
				last_rainfall_reading_since_9am_mm = rain_since_9am_mm
				
				already_exists = !current_station_record.latest_weather_readings.where(created_at: read_datetime)[0].nil?
				
				# the reading that we're about to add already exists, skip to the next reading.
				if(already_exists) 
				    if(TRACE) then puts("Record for time: #{read_datetime.to_s} already exists.") end
				    next 
				end
				
				if(TRACE) then puts("Rain last hour mm: " + rain_last_hour_mm.to_s) end
				
				# Save this weather reading to database if it's not already in there
				# Criteria for already existing: Something already exists with same name and read time
				
				new_weather_reading = LatestWeatherReading.new
				
				new_weather_reading.created_at = read_datetime
				new_weather_reading.station_id = current_station_record.id
				new_weather_reading.rainfall_mm_last_hour = rain_last_hour_mm
				new_weather_reading.wind_speed = wind_speed_kph * 0.277778 # convert to m/s
				new_weather_reading.wind_direction = wind_angle
				new_weather_reading.temperature = temperature
				
				new_weather_reading.save
				
			end
		elsif
			if(DEBUG) then puts("No details json found for area") end
		end
		
		# get monthly history link
		recent_months_url = area_details_page.search('a').
		select { |a| !a.nil? }.
		select { |a| !a.attribute('title').nil? }.
		select { |link| link.attribute('title').text.start_with?('Recent months at') }.
		map { |title| title.attribute('href').text }[0]
		
		if(!recent_months_url.nil?)
			if(DEBUG) then puts("Opening monthly history page: " + recent_months_url) end
			# open page for monthly history
			recent_months_page = Nokogiri::HTML(open(BOM_BASE_URL + recent_months_url))
			
			# Find the url for the CSV download
			recent_months_csv_url = recent_months_page.search('a').
			select { |a| !a.nil? }.
			select { |a| !a.attribute('title').nil? }.
			select { |link| link.attribute('title').text.start_with?('Comma Separated Value (.csv) file') }.
			map { |title| title.attribute('href').text }[0]
			
			if(!recent_months_csv_url.nil?)
				if(DEBUG) then puts("Opening monthly history csv: " + recent_months_csv_url) end
				# open and parse the csv
				header_row = nil
				station_record = current_station_record
				CSV.parse(open(BOM_BASE_URL + recent_months_csv_url).string) do |row|
					if(station_record.nil? && !row.nil? && row.count == 1 && !row[0].nil? && row[0].start_with?("Daily Weather Observations for"))
						station_name = normalise_name(row[0].split(',')[0].gsub("Daily Weather Observations for",""))
						station_record = station = Station.where({ name: station_name })[0]					
					elsif(!row.nil? && row.count > 1)
						if(!header_row.nil?)
							reading_date = Date.parse(row[header_row.index{|val| !val.nil? && val.start_with?("Date")}])
							rainfall = row[header_row.index{|val| !val.nil? && val.start_with?("Rainfall")}].to_f
							
							temp_9am = row[header_row.index{|val| !val.nil? && val.start_with?("9am Temp")}].to_f
							wind_speed_9am = row[header_row.index{|val| !val.nil? && val.start_with?("9am wind speed")}].to_f
							wind_angle_9am = bearing_to_angle(row[header_row.index{|val| !val.nil? && val.start_with?("9am wind direction")}])
							
							temp_3pm = row[header_row.index{|val| !val.nil? && val.start_with?("3pm Temp")}].to_f
							wind_speed_3pm = row[header_row.index{|val| !val.nil? && val.start_with?("3pm wind speed")}].to_f
							wind_angle_3pm = bearing_to_angle(row[header_row.index{|val| !val.nil? && val.start_with?("3pm wind direction")}])
							
							
							if(TRACE) then puts("Date: #{reading_date.to_s}") end
							if(TRACE) then puts("Rainfall: #{rainfall.to_s}") end
							
							if(TRACE) then puts("Temp 9am: #{temp_9am.to_s}") end
							if(TRACE) then puts("Wind speed 9am: #{wind_speed_9am.to_s}") end
							if(TRACE) then puts("Wind angle 9am: #{wind_angle_9am.to_s}") end
							
							if(TRACE) then puts("Temp 3pm: #{temp_3pm.to_s}") end
							if(TRACE) then puts("Wind speed 3pm: #{wind_speed_3pm.to_s}") end
							if(TRACE) then puts("Wind angle 3pm: #{wind_angle_3pm.to_s}") end
							
							if(station_record.nil?)
								if(DEBUG) then puts("Station record not found for daily readings!") end
								next
							end
							
							
							reading_datetime_9am = (reading_date.to_datetime + Time.parse("09:00").seconds_since_midnight.seconds)
							reading_datetime_3pm = (reading_date.to_datetime + Time.parse("15:00").seconds_since_midnight.seconds)
							
							#Save this to database
							# Create two readings, one for 9am and one for 3pm
							already_exists_9am = !station_record.daily_weather_readings.where(created_at: reading_datetime_9am)[0].nil?
							
							already_exists_3pm = !station_record.daily_weather_readings.where(created_at: reading_datetime_3pm)[0].nil?
							
							# Do 9am reading
							
							if(already_exists_9am)
							    # the reading that we're about to add already exists, skip to the next reading.
								if(TRACE) then puts("Record for time: #{reading_datetime_9am.to_s} already exists.") end
								next 
							end
							
							# Save this weather reading to database if it's not already in there
							# Criteria for already existing: Something already exists with same name and read time
							
							new_weather_reading_9am = LatestWeatherReading.new
							
							new_weather_reading_9am.created_at = reading_datetime_9am
							new_weather_reading_9am.station_id = station_record.id
							new_weather_reading_9am.rainfall_mm_last_hour = rainfall
							new_weather_reading_9am.wind_speed = wind_speed_9am * 0.277778 # convert to m/s
							new_weather_reading_9am.wind_direction = wind_angle_9am
							new_weather_reading_9am.temperature = temp_9am
							
							new_weather_reading_9am.save
							
							# Do 3pm reading
							
							if(already_exists_3pm)
							    # the reading that we're about to add already exists, skip to the next reading.
								if(TRACE) then puts("Record for time: #{reading_datetime_3pm.to_s} already exists.") end
								next 
							end
							
							# Save this weather reading to database if it's not already in there
							# Criteria for already existing: Something already exists with same name and read time
							
							new_weather_reading_3pm = LatestWeatherReading.new
							
							new_weather_reading_3pm.created_at = reading_datetime_3pm
							new_weather_reading_3pm.station_id = station_record.id
							new_weather_reading_3pm.rainfall_mm_last_hour = rainfall
							new_weather_reading_3pm.wind_speed = wind_speed_3pm * 0.277778 # convert to m/s
							new_weather_reading_3pm.wind_direction = wind_angle_3pm
							new_weather_reading_3pm.temperature = temp_3pm
							
							new_weather_reading_3pm.save
							
						elsif(!(row.index {|val| !val.nil? && val.start_with?('Date') }).nil?)
							header_row = row
						end
					end
				end
			elsif
				if(DEBUG) then puts("No monthly history csv found for area") end
			end
		elsif
			if(DEBUG) then puts("No monthly history page found for area") end
		end
	end
	
	def bearing_to_angle(bearing)
		if(bearing.nil?)
	        return nil
		end
		
		bearing_normalised = bearing.gsub(/[^0-9A-Za-z\\s]/i, '').upcase
		
		if(bearing_normalised == "N")
			return 0
		elsif(bearing_normalised == "NNE")
			return 22.5
		elsif(bearing_normalised == "NE")
			return 45
		elsif(bearing_normalised == "ENE")
			return 67.5
		elsif(bearing_normalised == "E")
			return 90
		elsif(bearing_normalised == "ESE")
			return 112.5
		elsif(bearing_normalised == "SE")
			return 135
		elsif(bearing_normalised == "SSE")
			return 157.5
		elsif(bearing_normalised == "S")
			return 180
		elsif(bearing_normalised == "SSW")
			return 202.5
		elsif(bearing_normalised == "SW")
			return 225
		elsif(bearing_normalised == "WSW")
			return 247.5
		elsif(bearing_normalised == "W")
			return 270
		elsif(bearing_normalised == "WNW")
			return 292.5
		elsif(bearing_normalised == "NW")
			return 315
		elsif(bearing_normalised == "NNW")
			return 337.5
		end
		
		# if no matches, return nil
		return nil
	end
	
	def normalise_name(name)
	    # convert to lowercase, then remove all non-alphanumberic characters,
	    # then replace spaces with - 
		return name.downcase.strip().gsub(/[^0-9a-z]/i, '').gsub(' ','-')
	end
end