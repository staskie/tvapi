current_file_location = File.expand_path(File.dirname(__FILE__))

# Require database connection
require File.join(current_file_location, "../lib/db/database_connection")

# Require models
Dir[File.join(current_file_location, "../lib/models", "*.rb")].each { |f| require f };

# Require parsers
Dir[File.join(current_file_location, "../lib/parsers", "*.rb")].each { |f| require f };

# Require libraries
Dir[File.join(current_file_location, "../lib", "*.rb")].each { |f| require f };


# Setting up logger

require 'log4r'
include Log4r

logger = Logger.new 'main'
logger.outputters << Outputter.stderr
logger.outputters << FileOutputter.new('update_programs', 
                            :filename => File.join(current_file_location, '../server/log/update_programs.log'))
logger.level = INFO
