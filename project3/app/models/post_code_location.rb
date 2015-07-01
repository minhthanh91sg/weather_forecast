class PostCodeLocation < ActiveRecord::Base
	has_many :stations
end
