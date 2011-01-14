$: << File.join(File.dirname(__FILE__), "../config")

require 'sinatra'
require 'builder'
require 'environment'

get '/' do
  @date = Time.now.strftime("%Y-%m-%d")
  @host_name = host_name
  erb :index
end

get '/test' do
  "hello"
end

get '/channels/?' do
  builder do |xml|
    xml.instruct! :xml, :version => 1.0
    
    xml.channels :source => "WP" do
      data_source.channels.each do |channel|
        xml.channel channel.name, :id => channel.data_source_channel_id
      end    
    end
  end 
end

get '/channel/:id/programs/?' do
  channel = data_source.channels.find_by_data_source_channel_id(params[:id])
  return exception("Channel id #{params[:id]} does not exist.") if channel.nil?
  date = Time.now.strftime("%Y-%m-%d")

  channels_program(channel, date)
end 

get '/channel/:id/programs/:date/?' do
  return exception("Invalid date argument. It has to be in format YYYY-mm-dd") unless params[:date] =~ /^\d{4}-\d{2}-\d{2}$/
  
  channel = data_source.channels.find_by_data_source_channel_id(params[:id])
  return exception("Channel id #{params[:id]} does not exist.") if channel.nil?
    
  date = params[:date]
  channels_program(channel, date)
end

def channels_program(channel, date)
  builder do |xml|
    xml.instruct! :xml, :version => 1.0
    
    xml.channel :id => channel.data_source_channel_id, :name => channel.name, :date => date do
      channel.programs.where("date = '#{date}'").each do |program|
        xml.program do
          xml.name        program.name
          xml.time        program.starttime
          xml.duration    program.duration
          xml.description program.description
          xml.episode     program.episode
          xml.category    program.category
        end
      end
    end
  end
end

def exception(msg)
  builder do |xml|
    xml.exception msg
  end
end

def host_name
  port = request.port
  port == 80 ? request.host : request.host + ":" + port.to_s
end

after do
  # Close connections after each request
  ActiveRecord::Base.clear_active_connections!
end


def data_source
  TvAPI::DataSource.find_by_name("WP")
end

