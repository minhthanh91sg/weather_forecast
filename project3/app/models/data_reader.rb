require 'date'
require 'geo-distance'
GeoDistance.default_algorithm = :haversine

class DataReader
end

class WeatherReader < DataReader

	@station_list = Station.all
	

	def self.nearest_stations_readings lat,long,start_date_string,end_date_string,latest_or_daily,number_of_stations
		#then find the nearest station for post_code
		start_date = Date.parse(start_date_string)
		end_date = Date.parse(end_date_string)

		lat_p = lat
		long_p = long
		dist_list = []
		@station_list.each do |s|
			name_s = s.name
			id_s = s.id
			lat_s = s.lat
			long_s = s.long
			dist_p_s = GeoDistance.distance( lat_p, long_p, lat_s, long_s ).km.number
			dist_struct = Struct.new(:id, :name, :dist_p_s)
			distance_s = dist_struct.new
			distance_s.id = id_s
			distance_s.name = s.name
			distance_s.dist_p_s = dist_p_s
			dist_list << distance_s
		end
		top_n_stations = dist_list.sort_by(&:dist_p_s)[0,number_of_stations]
		top_n_stations_readings = []
		if latest_or_daily == "latest"			
			top_n_stations.each do |top_n|
				station_readings = Station.find_by(name: top_n.name).latest_weather_readings.where(:created_at => (start_date.beginning_of_day..end_date.end_of_day))
				top_n_stations_readings << station_readings
			end	
		elsif latest_or_daily == "daily"
			top_n_stations.each do |top_n|
				station_readings = Station.find_by(name: top_n.name).daily_weather_readings.where(:created_at => (start_date.beginning_of_day..end_date.end_of_day))
				top_n_stations_readings << station_readings
			end
		end	
		return top_n_stations,top_n_stations_readings
	end





	def self.locations
		@station_list = Station.all
		last_update_list = []
		@station_list.each do |station|
			lrl = station.latest_weather_readings.last
			if(!lrl.nil?)
				last_update_list << lrl.updated_at.strftime("%H:%M%p %d-%m-%Y")
			else
				last_update_list << "never updated"
			end
		end
		return Date.today.strftime("%d-%m-%Y"),@station_list,last_update_list
	end



	def self.location_id_date location_id,date_string
		date = Date.parse(date_string)
		station = Station.find_by(name: location_id)
		if(!station.nil?)
			@location_id_date_list = station.latest_weather_readings.where(:created_at => (date.beginning_of_day..date.end_of_day))
			if @location_id_date_list.length == 0
				@location_id_date_list = "no data for given date"
			end
			@current_reading = station.latest_weather_readings.where(:created_at => (30.minutes.ago..DateTime.now))
			if @current_reading.length == 0
				@current_temp = "null"
			else
				@current_temp = @current_reading.temperature
			end
		else
			@location_id_date_list = "station not found"
			@current_temp = "null"
		end
		return @location_id_date_list,@current_temp
	end
	


	def self.post_code_date post_code,date_string
		date = Date.parse(date_string)
		p = PostCodeLocation.find_by(id: post_code)
		if(!p.nil?)
			lat_p = p.lat
			long_p = p.long
			top1 = WeatherReader.nearest_stations_readings(p.lat,p.long,date_string,date_string,"latest",1)
			top1_stations_readings = top1[1][0]			
			if top1_stations_readings.length == 0
				top1_stations_readings = "no data for given date"
			end
		else
			top1_stations_readings = "post code not found"
		end
		return top1_stations_readings,date_string
	end



	def self.nearest_stations_readings_prediction lat,long,start_time_string,end_time_string,latest_or_daily,number_of_stations
		#then find the nearest station for post_code
		start_time = DateTime.parse(start_time_string)
		end_time = DateTime.parse(end_time_string)

		lat_p = lat
		long_p = long
		dist_list = []
		@station_list.each do |s|
			name_s = s.name
			id_s = s.id
			lat_s = s.lat
			long_s = s.long
			dist_p_s = GeoDistance.distance( lat_p, long_p, lat_s, long_s ).km.number
			dist_struct = Struct.new(:id, :name, :dist_p_s)
			distance_s = dist_struct.new
			distance_s.id = id_s
			distance_s.name = s.name
			distance_s.dist_p_s = dist_p_s
			dist_list << distance_s
		end
		top_n_stations = dist_list.sort_by(&:dist_p_s)[0,number_of_stations]
		top_n_stations_readings = []
		if latest_or_daily == "latest"			
			top_n_stations.each do |top_n|
				station_readings = Station.find_by(name: top_n.name).latest_weather_readings.where(:created_at => (start_time..end_time))
				top_n_stations_readings << station_readings
			end	
		elsif latest_or_daily == "daily"
			top_n_stations.each do |top_n|
				station_readings = Station.find_by(name: top_n.name).daily_weather_readings.where(:created_at => (start_time.beginning_of_day..end_time.end_of_day))
				top_n_stations_readings << station_readings
			end
		end	
		return top_n_stations,top_n_stations_readings
	end



	def self.get_field_for_predition lat,long,start_time_string,end_time_string,latest_or_daily,field_name,number_of_stations
		#p = PostCodeLocation.find_by(ipost_code)
		#lat_p = p.lat
		#long_p = p.long 
		field_stations_array = []
		field_stations_index_array = []
		top_n = WeatherReader.nearest_stations_readings_prediction(lat,long,start_time_string,end_time_string,latest_or_daily,number_of_stations)
		top_n_stations = top_n[0]
		top_n_stations_readings = top_n[1]
		top_n_stations_readings.each do |topn_s|
			record_value_array = []
			record_index_array = []
			index = 1
			topn_s.each do |station_r|
				if field_name == "temperature"
					t = station_r.temperature
					if (!t.nil?)
						record_value_array << t
						record_index_array << index
					end
					index += 1
				elsif field_name == "wind_speed"
					ws = station_r.wind_speed
					if (!ws.nil?)
						record_value_array << ws
						record_index_array << index
					end
					index += 1
				elsif field_name == "wind_direction"
					wd = station_r.wind_direction
					if (!wd.nil?)
						record_value_array << wd
						record_index_array << index
					end
					index += 1
				elsif field_name == "rainfall"
					r = station_r.rainfall_mm_last_hour
					if (!r.nil?)
						record_value_array << r
						record_index_array << index
					end
					index += 1 
				end
			end		
			field_stations_array <<	record_value_array
			field_stations_index_array << record_index_array
		end


		top_n_dist = []
		top_n_stations.each do |s|
			top_n_dist << s.dist_p_s
		end
		return field_stations_array,field_stations_index_array,top_n_dist
	end

end




