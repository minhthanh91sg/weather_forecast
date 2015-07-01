require 'date'

json.post_code @post_code

if not @post_prediction_info.is_a?(String)
	@post_predictions = @post_prediction_info[0]
	@post_time_period = @post_prediction_info[1]
	

	@index = @post_time_period.map{|elem| elem*10}
	@index_prediction = @post_predictions.zip(@index)

	json.predictions @index_prediction.each do |in_p|
		time_stamp = (Time.now + 60*in_p[1]).strftime("%H:%M%p %d-%m-%Y")
		json.set! in_p[1] do
			json.set! :time, time_stamp
			json.set! :temperature do
				if(in_p[0][0].is_a?(String))
					json.set! :message, in_p[0][0]
				else
					json.set! :value,in_p[0][0][0]
					json.set! :probability,in_p[0][0][1]
				end
			end

			json.set! :wind_direction do
				if(in_p[0][1].is_a?(String))
					json.set! :message, in_p[0][1]
				else
					json.set! :value,in_p[0][1][0]
					json.set! :probability,in_p[0][1][1]
				end
			end

			json.set! :wind_speed do
				if in_p[0][2].length == 2
					json.set! :value,in_p[0][2][0]
					json.set! :probability,in_p[0][2][1]
				else
					json.set! :message, in_p[0][2]
				end
			end

			json.set! :rainfall do
				if in_p[0][3].length == 2
					json.set! :value,in_p[0][3][0]
					json.set! :probability,in_p[0][3][1]
				else
					json.set! :message, in_p[0][3]
				end
			end

		end

	end

else
	json.message @post_prediction_info
end


