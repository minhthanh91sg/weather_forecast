require 'csv'
require 'matrix'
require 'descriptive_statistics'
include Math

class Regressor

	def initialize
		if not (self.respond_to? :regress)
			throw Exception.new("need to implement regress method")
		end
	end

	def self.sum_squares_total a
		sum = 0
		a.each {|elem| sum = sum + elem}
		sum = Float(sum)
		avg = sum/(a.length)
		distance_from_mean = []
		a.each {|e| distance_from_mean << (e - avg)}
		sum_squares_total = 0
		distance_from_mean.each {|e| sum_squares_total = sum_squares_total + e**2 }	
		return sum_squares_total
	end

	def self.error_calc r, t, d
		sum = 0
		for l in 0..r.size-1
			sum = sum + r[l]*(t**l)
		end

		e = d - sum
		return e
	end


	def self.all_error r, t, d
		err = []
		for m in 0..t.size-1
			err << (error_calc r,t[m],d[m])
		end
		return err
	end
end

class SimpleRegressor < Regressor


	def self.regress time, data_point
		data_point_sst = sum_squares_total data_point
		r1 = polynomial_regress time,data_point,1
		r1.map!{|e| e.round(2)}
		err1 = all_error r1, time, data_point
		sse1 = 0
		err1.each{|e| sse1 = sse1 + e**2}
		r_sqr1 = 1 - (sse1/data_point_sst)
		return [r1,r_sqr1,"simple"]
	end

	def self.polynomial_regress x_array, y_array, degree
		x_data = x_array.map { |x_i| (0..degree).map { |pow| (x_i**pow).to_f } }
		mx = Matrix[*x_data]
		my = Matrix.column_vector(y_array)
		@coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
	end
end

class PolynomialRegressor < Regressor


	def self.regress time,data_point
		data_point_sst = sum_squares_total data_point
		r = []
		error_array = []
		r_sqr_poly = []
		reg = []

		#Calculate R^2 value
		for i in 2..10
			begin
				reg = polynomial_regress time, data_point, i
				reg.map!{|e| e.round(2)}
				r << reg
				err = all_error reg, time, data_point
				sse = 0
				err.each{|e| sse = sse + e**2}
				r_sqr_poly << (1 - sse/data_point_sst)	
			rescue ExceptionForMatrix::ErrNotRegular
				#if the matrix is sigular(not invertable, asign R square a abitrary large negtive number
				# and the coeficient array as empty
				r << []
				r_sqr_poly << -1000 	
 			end
		end

		#Find the best regression model based on r squared
		max_index = r_sqr_poly.rindex(r_sqr_poly.max)

		return [r[max_index],r_sqr_poly.max,"polynomial"]
	end

	def self.polynomial_regress x_array, y_array, degree
			x_data = x_array.map { |x_i| (0..degree).map { |pow| (x_i**pow).to_f } }
			mx = Matrix[*x_data]
			my = Matrix.column_vector(y_array)
			@coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
	end

end

class LogarithmicRegressor < Regressor


	def self.regress time,data_point
		data_point_sst = sum_squares_total data_point
		all_pos = true
		for i in 0..time.length-1
			if time[i] < 0 then
				all_pos = false
				return [nil,nil,"logarithmic"]
				break
			end
		end
		if all_pos == true then
			log_reg = logarithmic_regress time, data_point
			log_reg.map!{|e| e.round(2)}
			
			#predicted data based on log reg
			pred_data = []
			time.each {|e| pred_data << log_reg[0] + log_reg[1]*Math.log(e)}
			log_reg_error = []
			for i in 0..data_point.length-1
				log_reg_error[i] = data_point[i] - pred_data[i]
			end
			sse_log_reg = 0
			log_reg_error.each{|e| sse_log_reg = sse_log_reg + e**2}
			r_sqr_log_reg = 1 - (sse_log_reg/data_point_sst)
			return [log_reg, r_sqr_log_reg,"logarithmic"]
		end
	end

	def self.logarithmic_regress x_array, y_array
		n = x_array.length
		#sum of ys
		sum_y = 0
		y_array.each {|e| sum_y = sum_y + e}
		#array of log x
		log_x_array = []
		x_array.each {|t| log_x_array << Math.log(t)}
		#array of log x sqred
		log_x_sqr_array = []
		log_x_array.each {|e| log_x_sqr_array << e**2}
		#sum of (log x sqred)
		sum_log_x_sqr = 0
		log_x_sqr_array.each {|e| sum_log_x_sqr = sum_log_x_sqr + e}
		#sum of log x
		sum_log_x = 0
		log_x_array.each {|e| sum_log_x = sum_log_x + e}
		#array of y*logx
		y_logx = []
		for i in 0..x_array.length-1
			y_logx << y_array[i]*log_x_array[i]
		end	
		#sum of y*logx
		sum_y_logx = 0
		y_logx.each {|e| sum_y_logx = sum_y_logx + e}

		#b coeff
		b = (n*sum_y_logx - sum_y*sum_log_x)/(n*sum_log_x_sqr - sum_log_x**2)
		#a coeff
		a = (sum_y - b*sum_log_x)/(n)
		return [a,b]
	end

end

class ExponentialRegressor < Regressor


	def self.regress time,data_point
		data_point_sst = sum_squares_total data_point
		all_pos = true
		for i in 0..time.length-1
			if data_point[i] < 0 then
				all_pos = false
				return [nil,nil,"exponential"]
				break
			end
		end
		if all_pos == true
			exp_reg = exp_regress time, data_point
			exp_reg.map!{|e| e.round(2)}

			#predicted data based on log reg
			pred_data2 = []
			time.each {|e| pred_data2 << exp_reg[0]*E**(exp_reg[1]*e)}
			exp_reg_error = []
			for i in 0..data_point.length-1
				exp_reg_error[i] = data_point[i] - pred_data2[i]
			end

			sse_exp_reg = 0
			exp_reg_error.each {|e| sse_exp_reg = sse_exp_reg + e**2}
			r_sqr_exp_reg = 1 - (sse_exp_reg/data_point_sst)
			return[exp_reg,r_sqr_exp_reg,"exponential"]
		end
	end


	def self.exp_regress x_array, y_array 
		#Calculate the least square components: sum(lny),sum x^2,sum x,sum x*lny,(sum x)^2
		n = x_array.length
		log_y_array = []
		y_array.each {|e| log_y_array << Math.log(e)}
		sum_log_y = 0
		log_y_array.each {|e| sum_log_y = sum_log_y + e}
		x_sqr_array = []
		x_array.each {|e| x_sqr_array << e**2}
		sum_x = 0
		x_array.each {|e| sum_x = sum_x + e}
		sum_x_sqr = 0
		x_array.each {|e| sum_x_sqr = sum_x_sqr + e**2}
		x_logy = []
		for i in 0..n-1
			x_logy << x_array[i]*log_y_array[i]
		end
		sum_x_logy = 0
		x_logy.each {|e| sum_x_logy = sum_x_logy + e}

		#a coeff
		a = (sum_log_y*sum_x_sqr - sum_x*sum_x_logy)/(n*sum_x_sqr - sum_x**2)
		#b coeff
		b = (n*sum_x_logy - sum_x*sum_log_y)/(n*sum_x_sqr - sum_x**2)
		return [E**a,b]
	end
end

class BestRegressor < Regressor
	def self.regress time, data_point
		result_linear = SimpleRegressor.regress time,data_point
		result_poly = PolynomialRegressor.regress time,data_point
		result_log = LogarithmicRegressor.regress time,data_point
		result_exp = ExponentialRegressor.regress time,data_point
		result_array = []
		result_array << result_linear
		result_array << result_poly
		r_sqr_array = []
		r_sqr_array << result_linear[1]
		r_sqr_array << result_poly[1]
		#This set of if and elsif is to determine best fit in case some of the
		#regression model(s) cannot be used. The best fit model 
		#has largest r-sqred value
		if result_log[1] == nil && result_exp[1] == nil then		
			return result_array[r_sqr_array.rindex(r_sqr_array.max)]
		elsif result_log[1] == nil && result_exp[1] != nil then
			result_array<<result_exp
			r_sqr_array << result_exp[1]
			return result_array[r_sqr_array.rindex(r_sqr_array.max)]
		elsif result_log[1] != nil && result_exp[1] == nil then
			result_array<<result_log
			r_sqr_array << result_log[1]
			return result_array[r_sqr_array.rindex(r_sqr_array.max)]
		elsif result_log[1] != nil && result_exp[1] != nil then
			result_array<<result_log
			result_array<<result_exp
			r_sqr_array << result_log[1]
			r_sqr_array << result_exp[1]
			return result_array[r_sqr_array.rindex(r_sqr_array.max)]
		end

	end

	def self.calculate regression, x
		if regression[2] == "simple"
			return (regression[0][0] + regression[0][1]*x)
		elsif regression[2] == "polynomial"
			result = 0
			for l in 0..(regression[0].size-1)
				result = result + regression[0][l]*(x**l)
			end
			return result
		elsif regression[2] == "logarithmic"
			result = regression[0][0] + regression[0][1]*Math.log(x)
			return result		
		elsif regression[2] == "exponential"
			result = regression[0][0]*E**(regression[0][1]*x)
			return result
		end
	end
end



