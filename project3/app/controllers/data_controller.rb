require 'data_reader'

class DataController < ApplicationController
 
  def locations
  	#respond_to do |format|
  		#format.html 
  		#format.json
  	#end
  	locations_info = WeatherReader.locations
  	@date_today = locations_info[0]
  	@locations = locations_info[1]
  	@update_dates = locations_info[2]


  	#return locations_info #render json: @location 
  end

  def location_id_date
  	location_id_dates_info = WeatherReader.location_id_date(params[:location_id],params[:date])
  	@location_id_dates = location_id_dates_info[0]
  	@current_temp = location_id_dates_info[1]
  end

  def post_code_date
  	post_date_readings_info = WeatherReader.post_code_date(params[:post_code],params[:date])
  	@post_date_readings = post_date_readings_info[0]
  	@query_date = post_date_readings_info[1]
  end

end
