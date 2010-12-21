require 'spec_helper'

describe Channel do
  it "should not be valid if name, data_source_channel_id or data_source_id was missing, empty or nil" do
    channel = Channel.new(:data_source_channel_id => "1", :data_source_id => 1)
    channel.should_not be_valid
    
    channel = Channel.new(:name => "Example", :data_source_channel_id => "121", :data_source_id => nil)
    channel.should_not be_valid

    channel = Channel.new(:name => "Example", :data_source_channel_id => "", :data_source_id => 1)
    channel.should_not be_valid
  end
end
