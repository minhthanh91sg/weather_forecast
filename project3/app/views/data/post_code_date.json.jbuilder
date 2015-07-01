require 'date'

if(@post_date_readings.is_a?(String))
	json.measurements @post_date_readings
else
	json.date @query_date
	json.measurements @post_date_readings do |post_date|
		json.time post_date.created_at.strftime("%H:%M:%S%p")
		json.temp post_date.temperature
		json.precip post_date.rainfall_mm_last_hour
		json.wind_direction post_date.wind_direction
		json.wind_speed post_date.wind_speed
	end
end