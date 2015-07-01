require 'prediction_assistant'

class PredictionController < ApplicationController

  
	def post_code_period
		@post_prediction_info = PredictionAssistant.predict_by_post_code(params[:post_code],params[:period].to_i)
		@post_code = params[:post_code]
	end

	def lat_long_period
  		@geo_predictions_info = PredictionAssistant.predict_by_lat_long(params[:lat].to_f,params[:long].to_f,params[:period].to_i)
  		@lat = params[:lat]
  		@long = params[:long]
	end
end