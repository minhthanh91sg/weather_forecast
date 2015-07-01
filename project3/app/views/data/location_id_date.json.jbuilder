require 'date'

if(@location_id_dates.is_a?(String))
	json.measurements @location_id_dates
else
	json.date Date.today.strftime("%d-%m-%Y")
	json.current_temp @current_temp
	json.current_cond "not provided by source bom"
	json.measurements @location_id_dates do |loc_date|
		json.time loc_date.created_at.strftime("%H:%M:%S%p")
		json.temp loc_date.temperature
		json.precip loc_date.rainfall_mm_last_hour
		json.wind_direction loc_date.wind_direction
		json.wind_speed loc_date.wind_speed
	end
end