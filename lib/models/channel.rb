module TvAPI
  class Channel < ActiveRecord::Base
    belongs_to :data_source
    has_many :programs
  
    validates_presence_of :name, :data_source_channel_id, :data_source_id
  end
end