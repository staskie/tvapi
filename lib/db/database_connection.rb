require 'rubygems'
require 'active_record'
require 'yaml'

dbconfig = YAML::load(File.open(File.join(File.dirname(File.expand_path(__FILE__)), "../../config/database.yml")))

if (ENV["RAILS_ENV"] == 'test') 
  ActiveRecord::Base.establish_connection(dbconfig['test'])
else 
  ActiveRecord::Base.establish_connection(dbconfig['production'])
end

