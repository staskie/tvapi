require 'spec_helper'

describe "Application" do
  it "should receive arguments' list for initialization" do
    app = Application.new([])
    app.should respond_to :run
  end
  
  it "should parse wp website if such parser selected" do
    args = ["-p", "WP"]    
    app = Application.new(args)
    app.options[:parser].should == "WP"
    
    # Check both parameters
    args = ["--parser", "WP"]
    app = Application.new(args)    
    app.options[:parser].should == "WP"
  end
  
  it "should exit if parser wasn't selected" do
    DataCollector.should_not_receive(:new)

    app = Application.new([])
    app.should_receive(:puts)
    lambda { app.run }.should raise_error SystemExit
  end
  
  it "should retrieve a proper data source from the database" do
    args = ["-p", "WP"]
    
    dc_mock = mock(DataCollector)
    DataCollector.should_receive(:new).with("WP").and_return(dc_mock)
    dc_mock.should_receive(:channels)
    dc_mock.should_receive(:weekly_program)
    
    app = Application.new(args)
    Log4r::Logger['main'].should_receive(:info).any_number_of_times
    app.run
  end
  
  it "should reload channels is a valid argument is provided" do
    args = ["--reload-channels", "-p", "WP"]
    
    dc_mock = mock(DataCollector)
    DataCollector.should_receive(:new).with("WP").and_return(dc_mock)
    dc_mock.should_receive(:reload_channels)
    dc_mock.should_receive(:weekly_program)
    
    app = Application.new(args)
    app.options[:reload_channels].should == true
    Log4r::Logger['main'].should_receive(:info).any_number_of_times
    app.run
  end
  
  it "should get tv program only for one day if a valid argument provided" do
    args = ["-d", "2010-11-10", "-p", "WP"]
    
    dc_mock = mock(DataCollector)
    DataCollector.should_receive(:new).with("WP").and_return(dc_mock)
    dc_mock.should_receive(:get_programs).with(:date => "2010-11-10")
    
    app = Application.new(args)
    app.options[:date].should == "2010-11-10"   
    Log4r::Logger['main'].should_receive(:info).any_number_of_times
    app.run
  end
  
  it "should reload program for a given date if a valid argument provided" do
    args = ["-d", "2010-11-10", "-p", "WP", "-r"]
    
    dc_mock = mock(DataCollector)
    DataCollector.should_receive(:new).with("WP").and_return(dc_mock)
    dc_mock.should_receive(:get_programs).with(:date => "2010-11-10", :reload => true)
    
    app = Application.new(args)
    app.options[:date].should == "2010-11-10"
    app.options[:reload_programs].should == true
    Log4r::Logger['main'].should_receive(:info).any_number_of_times
    app.run
  end
  
  it "should not get tv program for the invalid date" do
    args = ["-d", "20101110", "-p", "WP"]
    
    lambda do
      app = Application.new([])
      app.instance_eval { @args = args }
      app.should_receive(:puts)
      app.parse
    end.should raise_error SystemExit
  end
  
  it "should be verbose if a valid argument provided" do
    args = ["-v"]
    
    app = Application.new(args)
    Log4r::Logger['main'].level.should == Log4r::DEBUG
  end
    
  it "should print help message if -h option was provided and exit" do
    args = ["-h"]
    
    lambda do 
      app = Application.new([]) # a hack to create the instance and test parse method
      app.instance_eval { @args = args }
      app.should_receive(:puts)
      app.parse
    end.should raise_error SystemExit
  end
  
  it "should have an informative help message" do
    app = Application.new([])
    app.instance_variable_get(:@optparser).to_s.should match(/Available options/)    
  end
end

