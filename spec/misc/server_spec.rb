require 'spec_helper'

describe "WebService" do
  include Rack::Test::Methods
  
  def app
    @app ||= Sinatra::Application
  end
  
  it "should have a default data source" do
    app.send(:data_source).name.should == "WP"
  end
  
  it "should respond to '/'" do
    Time.stub!(:now).and_return(Time.parse("2010-11-25"))
    get '/'
    last_response.headers["Content-Type"].should match(/text\/html/)
    last_response.body.should match(/TV Program API/)
    last_response.body.should match(/2010-11-25/)  
  end
  
  it "should return a list of channels for /channels" do
    channel = Channel.new(:name => "TVCHANNELNAME", :data_source_channel_id => 4)
    
    data_source = mock(DataSource)
    DataSource.stub!(:find_by_name).with("WP").and_return(data_source)
    data_source.should_receive(:channels).and_return([channel])
    
    get '/channels'
    last_response.body.should match(/TVCHANNELNAME/)
  end
  
  describe "should respond with the programs for a channel" do
    before do
      data_source = DataSource.new(:name => "WP")
      channel = Channel.new(:name => "TVCHANNELNAME", :data_source_channel_id => 4)
      program = Program.new(:name => "Taniec z gwiazdami")
      programs = mock("programs")
      programs.should_receive(:where).and_return([program])

      DataSource.stub!(:find_by_name).with("WP").and_return(data_source)
      data_source.channels.stub!(:find_by_data_source_channel_id).and_return(channel)
      channel.should_receive(:programs).and_return(programs)
    end
    
    it "should return a program for a channel with a given id for /channel/1/programs" do
      Time.stub!(:now).and_return(Time.parse("2010-11-25"))
      
      get '/channel/1/programs'
      last_response.body.should match(/Taniec z gwiazdami/)
      last_response.body.should match(/2010-11-25/)
    end
  
    it "should return a pgoram for a channel with a given id and date for /channel/1/programs/date" do
      get '/channel/1/programs/2010-12-01'
      last_response.body.should match(/Taniec z gwiazdami/)
      last_response.body.should match(/2010-12-01/)
    end
  end
  
  it "should respond with nice xml info if couldn't find a channel for /channel/4/programs" do
    channel = Channel.new(:name => "TVCHANNELNAME", :data_source_channel_id => 4)
    
    data_source = DataSource.new(:name => "WP")
    data_source.should_receive(:channels).any_number_of_times.and_return([channel])
    data_source.channels.stub!(:find_by_data_source_channel_id).and_return(nil)
    DataSource.stub!(:find_by_name).with("WP").and_return(data_source)
    
    
    get '/channel/4/programs'
    last_response.body.should match(/Channel id 4 does not exist/)
    get '/channel/4/programs'
    last_response.body.should match(/Channel id 4 does not exist/)
  end
  
  it "should response with nice xml if a date format is incorrect for /channel/1/programs/date" do
     get '/channel/1/programs/20101201'
     last_response.body.should match(/Invalid date argument. It has to be in format YYYY-mm-dd/)
     
     get '/channel/1/programs/2010-01-011'
     last_response.body.should match(/Invalid date argument. It has to be in format YYYY-mm-dd/)
  end
  
end
