# encoding: utf-8
require 'spec_helper'

describe WPParser do
  before do
    @parser = WPParser.new
    @logger = Log4r::Logger['main']
  end

  describe "#link" do

    it "should adjust the URL for a given day and channel" do
      @parser.link(:date => "2010-11-23", :channel => "TVN").should == "http://tv.wp.pl/date,2010-11-23,name,missing,stid,ID,program.html"
    end
    
    it "should adjust the URL if neither day nor channel is available yet" do
      fixed_time = Time.parse("2010-11-25")
      Time.stub!(:now).and_return(fixed_time)
      
      @parser.link.should == "http://tv.wp.pl/date,2010-11-25,name,missing,stid,ID,program.html"
    end
    
    it "should adjust the URL for a given date and channel id" do
      @parser.link(:date => "2010-11-26", :channel_id => 10).should == "http://tv.wp.pl/date,2010-11-26,name,missing,stid,10,program.html" 
    end
    
    it "should adjust the URL if the nil date was passed" do
      fixed_time = Time.parse("2010-11-25")
      Time.stub!(:now).and_return(fixed_time)
      
      @parser.link(:channel => "TVP 1").should == "http://tv.wp.pl/date,2010-11-25,name,missing,stid,ID,program.html"
    end
  end

  describe "#channel" do
    it "should return a channel with valid station name" do
      @parser.should_receive(:get_html).and_return(mock_http_response("wp_output_for_existing_channel.html"))

      channel = @parser.channel(1)
      channel.should be_kind_of Channel
      channel.name.should == "TVP 1"
    end
    
    it "should return nil for invalid station id" do
      @parser.should_receive(:get_html).and_return(mock_http_response("wp_output_for_nonexisting_channel.html"))
      @parser.channel(1).should == nil
    end
    
    it "should fail nicely if can't connect to URL" do
      @parser.should_receive(:get_html).and_raise(nil)
      @parser.should_receive(:link).and_return("http://example.com")
      @parser.channel(2).should == nil
    end
  end

  describe "#available_channels" do
    it "should loop through channel ids and get the list of channels" do
      @parser.should_receive(:max_channel_id).and_return(2)
      
      channel = Channel.new(:name => 'TVP 1', :data_source_channel_id => 1)
      
      @parser.should_receive(:channel).with(1).once.and_return(channel)
      @logger.should_receive(:debug).with("Got channel id #{channel.data_source_channel_id} with name #{channel.name}")
      @parser.should_receive(:channel).with(2).once.and_return("")
      
      @parser.available_channels.should == Array(channel)
    end
  end
  
  describe "#clean_html" do
    it "should replace &nbsp with space" do
      "a&nbsp;b".clean.should == "a b"
    end
    
    it "should strip white spaces" do
      "\ta&nbsp;b\n".clean.should == "a b"
    end    
  end
  
  describe "#extract_tv_program" do
  
    it "should extract data from document with one program" do
      @parser.stub!(:get_html).and_return(mock_http_response("wp_program.html"), mock_http_response('tv_program_description.html'))
      
      doc = @parser.get_html("http://example.com")
      
      @parser.extract_tv_program(doc).size.should == 1
      @parser.extract_tv_program(doc).should be_kind_of Array
      
      program = @parser.extract_tv_program(doc).first
      program.starttime.should == "08:25"
      program.duration.should  == "(25 min.)"
      program.name.should  == "Radio Romans"
      program.description.should match(/^Agnieszka zrywa z Antonim/) 
      program.episode.should == "odc. 23"
      program.category.should == "obyczajowy,"
    end
    
    it "should extract data from complete document" do
      @parser.stub!(:get_html).and_return(mock_http_response("wp_output_for_existing_channel.html"))
      
      doc = @parser.get_html("http://example.com")
      @parser.extract_tv_program(doc).size.should > 0
    end
  end
  
  describe  "#extract_description" do
    it "should follow a link with description" do
      @parser.should_receive(:get_html).and_return(mock_http_response("wp_program.html"), mock_http_response('tv_program_description.html'))

      doc = @parser.get_html("http://example.com")

      programs = @parser.extract_tv_program(doc)
      programs.size.should == 1
      programs[0].should be_kind_of Program
      programs[0].description.should match(/^Agnieszka zrywa z Antonim/)
    end
  
    it "should ammend the link for description" do
      @parser.should_receive(:get_html).with("http://tv.wp.pl/name,Radio-Romans,prid,23528996718,opis.html").and_return(mock_http_response("tv_program_description.html"))
      @parser.extract_description("name,Radio-Romans,prid,23528996718,opis.html")
    end
    
    it "should parse the web page and return empty string if description couldn't be found" do
      doc_mock = mock("doc")
      @parser.stub!(:get_html).and_return(doc_mock)
      doc_mock.should_receive(:css).and_return(nil)
      
      @parser.extract_description("http://example.com").should == ""
    end     
    
    it "should parse the web page and return empty string when link method returns nil" do
      doc_mock = mock("doc")
      @parser.stub!(:get_html).and_return(nil)
      
      @parser.extract_description("http://example.com").should == ""    
    end 
    
    it "should parse the web page and return emptpy string when link method returns emptpy string" do
      doc_mock = mock("doc")
      @parser.stub!(:get_html).and_return(doc_mock)
      doc_mock.should_receive(:css).and_return(["", ""])
      
      @parser.extract_description("http://example.com").should == ""
    end
  end
  
  describe "#tv_program" do
    before(:each) do
      @channel = Channel.new(:name => 'TVP 1', :data_source_channel_id => 1)
    end
    
    it "should return tv programs for today if no date givem" do
      fixed_time = Time.parse("2010-11-25")
      Time.stub!(:now).and_return(fixed_time)
      @parser.stub!(:get_html).and_return(mock_http_response("wp_output_for_existing_channel.html"))
      
      @parser.tv_program(@channel).size.should > 10
    end
    
    it "should return tv programs for a given date" do
      @parser.stub!(:get_html).and_return(mock_http_response("wp_output_for_existing_channel.html"))
      @parser.tv_program(@channel, "2010-11-26").should be_kind_of Array
      @parser.tv_program(@channel, "2010-11-26").size.should == 41
    end
  end
end


def mock_http_response(file_name)
  file = File.join(File.expand_path(File.dirname(__FILE__)), "html_files",file_name)
  Nokogiri::HTML(open(file))
end

