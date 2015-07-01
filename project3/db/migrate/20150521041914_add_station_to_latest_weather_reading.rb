class AddStationToLatestWeatherReading < ActiveRecord::Migration
  def change
    add_reference :latest_weather_readings, :station, index: true
    add_foreign_key :latest_weather_readings, :stations
  end
end
