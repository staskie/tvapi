require 'rspec'
require 'rack/test'

ENV["RAILS_ENV"] ||= 'test'

require File.join(File.expand_path(File.dirname(__FILE__)), "../config/environment")
require File.join(File.expand_path(File.dirname(__FILE__)), "../server/server")
require File.join(File.expand_path(File.dirname(__FILE__)), "../bin/update_programs")

include TvAPI
include TvAPI::Parser


