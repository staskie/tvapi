# encoding: utf-8
require 'spec_helper'

describe DataCollector do
  before do
    @logger = Log4r::Logger['main']
    
    # Make sure db is empty
    Channel.destroy_all
    DataSource.destroy_all
    Program.destroy_all
    
    @data_source = DataSource.create(:name => "WP", :base_class => "WPParser", :source => "example.com")
    
  end
  
  describe " when initialized" do    
    it "with a valid parser name should respond to parser's methods" do
      dc = DataCollector.new("WP")
      dc.parser.should respond_to :available_channels
      dc.parser.should respond_to :tv_program
    end
    
    it "with invalid parser name should raise an exception" do
      lambda { DataCollector.new("ABC") }.should raise_error(ArgumentError)
    end    
  end
  
  describe "channels management" do
    before do
      # Make sure db is empty
      
      @channel1 = Channel.new(:name => "TVP 1",   :data_source_channel_id => 1)
      @channel2 = Channel.new(:name => "TVP 2",   :data_source_channel_id => 2)
      @channel3 = Channel.new(:name => "Polsat",  :data_source_channel_id => 5)
      @channels = []
      @channels << @channel1 << @channel2 << @channel3
    end
    
    it "shoud retrive and save available channels from www" do
      wp_parser = mock(WPParser)
      wp_parser.should_receive(:available_channels).and_return(@channels)
      
      dc = DataCollector.new("WP")
      dc.should_receive(:parser).and_return(wp_parser)
      dc.channels
      
      @data_source.channels.size.should == 3
    end
        
    it "should not save channels if data source has any channels" do
      mock_data_source = mock(DataSource)
      mock_data_source.should_receive(:channels).and_return([1])
      
      dc = DataCollector.new("WP")
      dc.should_receive(:data_source).and_return(mock_data_source)
      dc.should_not_receive(:parser)
      @logger.should_receive(:info).with("Already found channels for this data source. If you want to update, run reload_channels")

      dc.channels
    end
    
    it "should remove channels and then retrieve them again from www" do
      @data_source.channels.create(:name => 'test name', :data_source_channel_id => 1)
      @data_source.channels.size.should == 1
      
      wp_parser = mock(WPParser)
      wp_parser.should_receive(:available_channels).and_return(@channels)
      
      dc = DataCollector.new("WP")
      dc.should_receive(:parser).and_return(wp_parser)
      dc.reload_channels
      
      @data_source.channels.size.should == @channels.size
    end
  end
  
  describe "program management" do
    before  do
      @channel1 = Channel.new(:name => "TVP 1",   :data_source_channel_id => 1)
      @channel2 = Channel.new(:name => "TVP 2",   :data_source_channel_id => 2)
      @channel3 = Channel.new(:name => "Polsat",  :data_source_channel_id => 5)
      @channels = []
      @channels << @channel1 << @channel2 << @channel3
      
      @data_source = DataSource.create(:name => "WP", :base_class => "WPParser")
      @data_source.channels << @channel1 << @channel2 << @channel3
      
      @program = Program.new(:name => "Taniec z gwiazdami")
      @dc = DataCollector.new("WP")
    end
    
    it "should request for a tv program for each channel for a given date" do
      @dc.should_receive(:data_source).and_return(@data_source)
      @data_source.channels.should_receive(:each).and_yield(@channel1).and_yield(@channel2).and_yield(@channel3)
      
      @dc.should_receive(:get_program_for).once.with(@channel1, "2010-11-30")
      @dc.should_receive(:get_program_for).once.with(@channel2, "2010-11-30")
      @dc.should_receive(:get_program_for).once.with(@channel3, "2010-11-30")
            
      @dc.get_programs(:date => "2010-11-30")
    end
    
    it "should request for a tv program for each channel for a current day if date wasn't given" do
      Time.stub!(:now).and_return(Time.parse("2010-12-05"))
      
      @dc.should_receive(:data_source).and_return(@data_source)
      @data_source.channels.should_receive(:each).and_yield(@channel1).and_yield(@channel2).and_yield(@channel3)

      @dc.should_receive(:get_program_for).once.with(@channel1, "2010-12-05")
      @dc.should_receive(:get_program_for).once.with(@channel2, "2010-12-05")
      @dc.should_receive(:get_program_for).once.with(@channel3, "2010-12-05")
      
      @dc.get_programs
    end
    
    it "should not try to download the program if it already exists in the database" do
      @dc.should_receive(:data_source).and_return(@data_source)
      @data_source.channels.should_receive(:each).and_yield(@channel1).and_yield(@channel2).and_yield(@channel3)
      
      @channel1.programs.should_receive(:where).with("date = '2010-12-05'").and_return(Array.new(10))
      @channel2.programs.should_receive(:where).with("date = '2010-12-05'").and_return(Array.new(15))
      @channel3.programs.should_receive(:where).with("date = '2010-12-05'").and_return(Array.new(0))
      
      @dc.should_receive(:get_program_for).once.with(@channel3, "2010-12-05")
      @logger.should_receive(:debug).with("Program for TVP 1 already exists for 2010-12-05 in the database. Skipping.")
      @logger.should_receive(:debug).with("Program for TVP 2 already exists for 2010-12-05 in the database. Skipping.")  

      @dc.get_programs(:date => "2010-12-05")
    end
    
    it "should download the program if it already exists in the database and reload flag is provided" do
      @dc.should_receive(:data_source).and_return(@data_source)
      @data_source.channels.should_receive(:each).and_yield(@channel1).and_yield(@channel2).and_yield(@channel3)
      
      programs = mock(Array)
      programs.should_receive(:count).and_return(10)
      programs.should_receive(:count).and_return(10)
      programs.should_receive(:count).and_return(0)
      programs.should_receive(:delete_all).exactly(3).times
      
      @channel1.programs.should_receive(:where).and_return(programs)
      @channel2.programs.should_receive(:where).and_return(programs)
      @channel3.programs.should_receive(:where).and_return(programs)

      
      @dc.should_receive(:get_program_for).once.with(@channel1, "2010-12-05")
      @dc.should_receive(:get_program_for).once.with(@channel2, "2010-12-05")
      @dc.should_receive(:get_program_for).once.with(@channel3, "2010-12-05")
      
      @logger.should_receive(:debug).with("Program for TVP 1 already exists, but will be reloaded.")
      @logger.should_receive(:debug).with("Program for TVP 2 already exists, but will be reloaded.")
      @logger.should_receive(:debug).with("Program for Polsat already exists, but will be reloaded.")
          
      @dc.get_programs(:date => "2010-12-05", :reload => true)
    end
    
    
    it "should get the program from www for a given channel" do
        @dc.parser.should_receive(:tv_program).with(@channel1, '2010-11-14').and_return([@program])
        @logger.should_receive(:debug).with("Getting a program for #{@channel1.name} for 2010-11-14")
        
        returned_programs = @dc.get_program_for(@channel1, '2010-11-14')

        program = returned_programs.first
        program.name.should == "Taniec z gwiazdami"
        program.date.should == "2010-11-14"
    end  
    
    describe "weekly program" do
      
      it "should pass the correct dates" do
        Time.stub!(:now).and_return(Time.parse("2010-12-06"))
        
        @dc.should_receive(:get_programs).with(:date => "2010-12-06")
        @dc.should_receive(:get_programs).with(:date => "2010-12-07")
        @dc.should_receive(:get_programs).with(:date => "2010-12-08")
        @dc.should_receive(:get_programs).with(:date => "2010-12-09")
        @dc.should_receive(:get_programs).with(:date => "2010-12-10")
        @dc.should_receive(:get_programs).with(:date => "2010-12-11")
        @dc.should_receive(:get_programs).with(:date => "2010-12-12")
        
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-06")
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-07")
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-08")
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-09")
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-10")
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-11")
        @logger.should_receive(:info).with("Getting TV Program for 2010-12-12")
                                          
        @dc.get_items_for_the_next_week
      end
      
      it "should delete programs that are older then today" do
        Time.stub!(:now).and_return(Time.parse("2010-12-06"))
        
        @logger.should_receive(:info).with("Deleting programs older then #{Time.now.strftime('%Y-%m-%d')}")
        program_mock = mock(Program)
        Program.should_receive(:where).with("date < '2010-12-06'").and_return(program_mock)
        program_mock.should_receive(:delete_all)
        
        @dc.remove_passed_programs
      end
      
      it "should update the database and remove old items" do
        @dc.should_receive(:remove_passed_programs)
        @dc.should_receive(:get_items_for_the_next_week)
        
        @dc.weekly_program
      end
    end
  end
end
