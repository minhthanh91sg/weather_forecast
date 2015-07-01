require 'predictor'

class PredictionAssistant

	def self.predict_by_lat_long lat,long,period
		period_list = []

		if period == 10
			period_list = [0,1]
		elsif period == 30
			period_list = [0,1,3]
		elsif period == 60
			period_list = [0,1,3,6]
		elsif period == 120
			period_list = [0,1,3,6,12]
		elsif period == 180
			period_list = [0,1,3,6,12,18]
		end

		prediction_result =[]
		if period_list == []
			return "time period not valid"
		else
			period_list.each do |p|
				t = TemperaturePredictor.new(lat,long,p)
				t_p = t.predict
				wd = WindDirectionPredictor.new(lat,long,p)
				wd_p = wd.predict
				ws = WindSpeedPredictor.new(lat,long,p)
				ws_p = ws.predict
				r = RainfallPredictor.new(lat,long,p)
				r_p = r.predict
				prediction_result << [t_p,wd_p,ws_p,r_p]
			end
		end
		return prediction_result,period_list
	end


	def self.predict_by_post_code post_code,period
		p = PostCodeLocation.find_by(id: post_code)
		if(!p.nil?)
			lat = p.lat
			long = p.long
			p = PredictionAssistant.predict_by_lat_long(lat,long,period)
			return p
		else
			return "post code not found"
		end
	end
end


