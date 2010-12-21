#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '../config')
require 'environment'
require 'optparse'

module TvAPI
  class Application
    DATE_FORMAT = /\d\d\d\d\-\d\d\-\d\d/
    
    attr_reader :options
    
    def initialize(args)
      @options = {}
      @args = args
      parse
    end
    
    def parse
      @optparser = OptionParser.new do |opts|
        opts.banner  = "Usage: #{$0} [OPTIONS]\n\n"
        opts.banner += "Example: #{$0} -p WP\n"
        opts.banner += "Example: #{$0} -p WP -d 2010-12-14 -r\n"
        
        opts.separator ""
        opts.separator "Available options:"
        
        opts.on("-p", "--parser WEBSITE", ["WP"], "Select website to parse. Available options: WP") do |dc|
          @options[:parser] = dc
        end
        
        opts.on("--reload-channels", "Reload channels") do
          @options[:reload_channels] = true
        end
        
        opts.on("-d", "--date DATE", "Download program only for a given date (YYYY-MM-DD)") do |date|
          if date !~ DATE_FORMAT
            puts "Invalid date format. Please use YYYY-MM-DD"
            exit
          end
          @options[:date] = date
        end
        
        opts.on("-r", "--[dont-]reload-programs", "Force reloading programs, even if they already exists") do 
          @options[:reload_programs] = true
        end
        
        opts.on("-v", "--verbose", "Run verbosely") do
          Log4r::Logger['main'].level = Log4r::DEBUG
        end
        
        opts.separator ""
        
        opts.on_tail("-h", "--help", "Print this help") do
          puts @optparser
          exit
        end
      end
      
      @optparser.parse!(@args)
    end
    
    def run
      if @options[:parser].nil?
        puts @optparser
        exit
      end
      
      logger_wrapper do
        collector = DataCollector.new(@options[:parser])
        
        if @options[:date] && @options[:reload_programs]
          # Reload all programs for a given date
          collector.get_programs(:date    => @options[:date], 
                                 :reload  => @options[:reload_programs])      
        elsif @options[:date] 
          collector.get_programs(:date => @options[:date])
        else
          # Get available channels or reload
          @options[:reload_channels].nil? ? collector.channels : collector.reload_channels
          collector.weekly_program
        end
      end
    end

    private
    
    def logger_wrapper
      logger = Log4r::Logger['main']
      start_time = Time.now
      logger.info "==============================================="
      logger.info "Program started at #{start_time}"

      yield if block_given?

      end_time = Time.now  
      minutes = (end_time - start_time) / 60
      
      logger.info "Program finished at #{end_time}. The whole run took around #{minutes.to_i} minute(s)"
      logger.info "==============================================="
      logger.info "\n\n"
    end  
  end
end



if __FILE__ == $0
  # Run the actual application here
  app = TvAPI::Application.new(ARGV)
  app.run
end
