# encoding: ISO-8859-2
module TvAPI
  class Program < ActiveRecord::Base
    belongs_to :channel
  
    validates_presence_of :name, :starttime, :channel_id, :date

  end
end