require 'regressor'
require 'data_reader'
require 'descriptive_statistics'
require 'date'

class Predictor
	def initialize *args
		if not (self.respond_to? :predict)
			throw Exception.new("need to implement predict method")
		end
	end

	def predict daily_info, latest_info, time
		daily_reading = daily_info[0]
		daily_time_point = daily_info[1]
		daily_data = daily_reading.zip(daily_time_point) 
		daily_sd = []
		daily_reading.each do |e|
			daily_sd << e.standard_deviation
		end
		daily_distance = daily_info[2]


		latest_reading = latest_info[0]
		latest_time_point = latest_info[1]
		latest_data = latest_reading.zip(latest_time_point)
		latest_distance = latest_info[2]

		daily_regress_result = []
		daily_predict_result = []
		print "daily_data = ", daily_data, "\n"
		daily_data.each do |d|
			#Arrays feed to regressor have to have length greater than 1
			if d[1].length > 1
				daily_regress = BestRegressor.regress d[1], d[0]
				daily_prediction = BestRegressor.calculate daily_regress, (d[1].last + time)
				print daily_regress,"\n"
				print daily_prediction,"\n"
				print (d[1].last + time), "\n"
			else
				daily_regress = []
				daily_prediction = nil
			end
			daily_regress_result << daily_regress
			daily_predict_result << [daily_prediction]
			puts "daily_regress_result="+ "#{daily_regress_result}"
			puts "daily_predict_result="+ "#{daily_predict_result}"			
		end


		latest_regress_result = []
		latest_predict_result = []
		print "latest_data = ",latest_data,"\n"
		latest_data.each do |l|
			#Arrays feed to regressor have to have length greater than 1
			if l[1].length > 1
				latest_regress = BestRegressor.regress l[1], l[0]	
				latest_prediction = BestRegressor.calculate latest_regress, (l[1].last + time)
				print latest_regress,"\n"
				print latest_prediction,"\n"
				print (l[1].last + time), "\n"
			else
				latest_regress = []
				latest_prediction = nil
			end
			latest_regress_result << latest_regress
			latest_predict_result << [latest_prediction]
			puts "latest_regress_result="+"#{latest_regress_result}"
			puts "latest_predict_result="+"#{latest_predict_result}"
		end





		result = []
		distance = []
		for i in 0..daily_predict_result.length-1
			if latest_predict_result[i].any? && daily_predict_result[i].any?
				if (latest_predict_result[i][0] - daily_predict_result[i][0]).abs <= ((1/daily_regress_result[i][1])*daily_sd[i]).abs
					result << [latest_predict_result[i][0],latest_regress_result[i][1]]
					distance << daily_distance[i]
				else
					result << [latest_predict_result[i][0],latest_regress_result[i][1]*daily_regress_result[i][1]]
					distance << daily_distance[i]
				end 
			end
		end
		#puts "distance =" + "#{distance}"
		puts "result="+ "#{result}"
		puts "daily_sd = " + "#{daily_sd}"




		final_result = [0,0]
		if not result.any?
			return "Insufficient data for prediction"
		elsif result.length <=1 || distance[0] == 0
			return result[0].map {|elem| elem.round(2)}
		else
			distance_weights = []
			distance.each do |d|
				d_weight = (distance.reduce(:+).to_f)/d 
				distance_weights << d_weight
			end
			for i in 0..result.length-1
				final_result[0] = final_result[0].to_f + result[i][0]*(distance_weights[i].to_f/distance_weights.reduce(:+).to_f)
				# Assuming 20km radius will have no compernsation on predict power(probability). Above that, using a factor to
				#adjust the accuracy  
				if distance[i] <= 20
					final_result[1] = final_result[1].to_f + result[i][1]*(distance_weights[i].to_f/distance_weights.reduce(:+).to_f)
				else
					final_result[1] = final_result[1].to_f + result[i][1]*(distance_weights[i].to_f/distance_weights.reduce(:+).to_f)*(20/distance[i])
				end
			end
			final_result_round = final_result.map {|elem| elem.round(2)}
			return final_result_round
		end
	end
end


class TemperaturePredictor < Predictor
	def initialize (lat,long,prediction_time)
		start_time_string = 24.hours.ago.strftime("%H:%M:%S %d-%m-%Y")
		end_time_string = DateTime.now.strftime("%H:%M:%S %d-%m-%Y")
		start_date_string = 7.days.ago.strftime("%d-%m-%Y")
		end_date_string = Date.today.strftime("%d-%m-%Y")
		@daily_info = WeatherReader.get_field_for_predition lat,long,start_date_string,end_date_string,"daily","temperature",3
		@latest_info = WeatherReader.get_field_for_predition lat,long,start_time_string,end_time_string,"latest","temperature",3
		@time = prediction_time
	end 

	def predict 
		super(@daily_info,@latest_info,@time)
	end

end

class WindSpeedPredictor < Predictor
	def initialize (lat,long,prediction_time)
		start_time_string = 24.hours.ago.strftime("%H:%M:%S %d-%m-%Y")
		end_time_string = DateTime.now.strftime("%H:%M:%S %d-%m-%Y")
		start_date_string = 7.days.ago.strftime("%d-%m-%Y")
		end_date_string = Date.today.strftime("%d-%m-%Y")
		@daily_info = WeatherReader.get_field_for_predition lat,long,start_date_string,end_date_string,"daily","wind_speed",3
		@latest_info = WeatherReader.get_field_for_predition lat,long,start_time_string,end_time_string,"latest","wind_speed",3
		@time = prediction_time
	end
	def predict
		super(@daily_info,@latest_info,@time)
	end
end


class WindDirectionPredictor < Predictor
	def initialize (lat,long,prediction_time)
		start_time_string = 24.hours.ago.strftime("%H:%M:%S %d-%m-%Y")
		end_time_string = DateTime.now.strftime("%H:%M:%S %d-%m-%Y")
		start_date_string = 7.days.ago.strftime("%d-%m-%Y")
		end_date_string = Date.today.strftime("%d-%m-%Y")
		@daily_info = WeatherReader.get_field_for_predition lat,long,start_date_string,end_date_string,"daily","wind_direction",3
		@latest_info = WeatherReader.get_field_for_predition lat,long,start_time_string,end_time_string,"latest","wind_direction",3
		@time = prediction_time
	end	

	def predict
		super(@daily_info,@latest_info,@time)
	end
end

class RainfallPredictor < Predictor
	def initialize (lat,long,prediction_time)
		start_time_string = 24.hours.ago.strftime("%H:%M:%S %d-%m-%Y")
		end_time_string = DateTime.now.strftime("%H:%M:%S %d-%m-%Y")
		start_date_string = 7.days.ago.strftime("%d-%m-%Y")
		end_date_string = Date.today.strftime("%d-%m-%Y")
		@daily_info = WeatherReader.get_field_for_predition lat,long,start_date_string,end_date_string,"daily","rainfall",3
		@latest_info = WeatherReader.get_field_for_predition lat,long,start_time_string,end_time_string,"latest","rainfall",3
		@time = prediction_time
	end 

	def predict
		super(@daily_info,@latest_info,@time)
	end

end