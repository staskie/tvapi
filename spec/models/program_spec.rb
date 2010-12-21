require 'spec_helper'

describe Program do
  it "should not be valid if name, startime, channel_id or date were missing, nil or empty" do
    program = Program.new(:name => "Taniec z gwiazdami",  :channel_id => nil, :date => "")
    program.should_not be_valid
    
    program = Program.new(:name => "", :starttime => "20:00", :channel_id => 1, :date => "2010-12-01")
    program.should_not be_valid

    program = Program.new(:name => "Taniec z gwiazdami", :starttime => "20:00", :channel_id => nil, :date => "2010-12-01")
    program.should_not be_valid
  end
end
