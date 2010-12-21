module TvAPI
  class DataSource < ActiveRecord::Base
    has_many :channels
  
    validates_presence_of :name, :source, :base_class
  end
end