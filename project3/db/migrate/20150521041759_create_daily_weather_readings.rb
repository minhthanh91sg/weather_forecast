class CreateDailyWeatherReadings < ActiveRecord::Migration
  def change
    create_table :daily_weather_readings do |t|
      t.float :rainfall_mm_last_hour
      t.float :wind_speed
      t.float :wind_direction
      t.float :temperature

      t.timestamps null: false
    end
  end
end
