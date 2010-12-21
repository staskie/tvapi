# encoding: utf-8
module TvAPI
  class DataCollector
  
    attr_accessor :parser, :data_source
  
    def initialize(parser_name)
      self.data_source = DataSource.find_by_name(parser_name)
      raise ArgumentError, "Invalid parser name #{parser_name}" if @data_source.nil?
      self.parser = eval "Parser::" + @data_source.base_class + '.new'
    
      @logger = Log4r::Logger['main']
    end
  
    #
    # Provide list of channels
    #
    def channels
      if self.data_source.channels.count != 0
        @logger.info "Already found channels for this data source. If you want to update, run reload_channels"
        return
      end
      get_channels
    end
  
    #
    # Remove channels from the database and download them again
    #
    def reload_channels
      self.data_source.channels.destroy_all
      get_channels
    end
  
    #
    # Retrieve channels from the web server and store them into the database
    #
    def get_channels
      self.parser.available_channels.each do |channel|
        self.data_source.channels << channel
      end
    end
  
    #
    # Retrieve programs for the channels
    #
    def get_programs(opts = {})
      opts = {  :date   => Time.now.strftime("%Y-%m-%d"),
                :reload => false }.merge(opts)
    
      self.data_source.channels.each do |channel|
        # List of programs for a channel and date
        channel_programs = channel.programs.where("date = '#{opts[:date]}'")

        if channel_programs.count != 0 && opts[:reload] == false
          @logger.debug "Program for #{channel.name} already exists for #{opts[:date]} in the database. Skipping."
        elsif opts[:reload]                
          @logger.debug "Program for #{channel.name} already exists, but will be reloaded."
          channel_programs.delete_all
          get_program_for(channel, opts[:date])
        else
          get_program_for(channel, opts[:date])
        end
      end
    end
  
    def get_program_for(channel, date)
      @logger.debug "Getting a program for #{channel.name} for #{date}"
      programs = self.parser.tv_program(channel, date)
      programs.each { |p| p.date = date}

      channel.programs << programs
    end
  
    def weekly_program
      remove_passed_programs
      get_items_for_the_next_week
    end
  
    #
    # As name indicates, getting the TV program for next seven days
    #
    def get_items_for_the_next_week
      (0...7).each do |i|
        date = (Time.now + i.days).strftime("%Y-%m-%d")
      
        @logger.info "Getting TV Program for #{date}"
        get_programs(:date => date)
      end
    end
  
    #
    # Do not store previous programs
    #
    def remove_passed_programs
      date = Time.now.strftime("%Y-%m-%d")
    
      @logger.info "Deleting programs older then #{date}"
      Program.where("date < '#{date}'").delete_all
    end
  end
end
