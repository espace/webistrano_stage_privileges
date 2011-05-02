class StagesUser < ActiveRecord::Base
  belongs_to :stage
  belongs_to :user
  
end
