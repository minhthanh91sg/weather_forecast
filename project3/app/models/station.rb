class Station < ActiveRecord::Base
	belongs_to :post_code_location
	has_many :daily_weather_readings
	has_many :latest_weather_readings
end
