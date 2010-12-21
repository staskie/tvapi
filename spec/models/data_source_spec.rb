require 'spec_helper'

describe DataSource do
  it "should not be valid if name, source or base_class was missing, empty or nil" do
    data_source = DataSource.new(:source => "example.com", :base_class => "Example")
    data_source.should_not be_valid
    
    data_source = DataSource.new(:name => "Example", :source => "", :base_class => "Example")
    data_source.should_not be_valid
    
    data_source = DataSource.new(:name => "Example", :source => "example.com", :base_class => nil)
    data_source.should_not be_valid
  end
end
