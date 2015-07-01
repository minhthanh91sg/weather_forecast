require 'date'
json.date @date_today 
i = 0
json.locations @locations do |location|
	json.id location.name
	json.lat location.lat
	json.lon location.long
	json.last_update @update_dates[i]
	i+=1
end