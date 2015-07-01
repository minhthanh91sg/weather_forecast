class AddStationToDailyWeatherReading < ActiveRecord::Migration
  def change
    add_reference :daily_weather_readings, :station, index: true
    add_foreign_key :daily_weather_readings, :stations
  end
end
