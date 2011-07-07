# encoding: iso-8859-2
require 'nokogiri'
require 'open-uri'

class String
  #
  # Getting rid of unwanted characters from the HTML
  #    
  def clean
    self.strip!
    self.gsub!(/&nbsp;/,' ')
    self  
  end
end

module TvAPI
  module Parser
    class WPParser

      TV_WP_URL = "http://tv.wp.pl/date,DATE,name,missing,stid,ID,program.html"
      MAX_CHANNEL_ID = 500
      MAX_NUMBER_OF_TRIES = 2
      WP_BASE_HTTP_LINK = "http://tv.wp.pl/"
  
      def initialize
        @logger = Log4r::Logger['main']
      end

      #
      # Connects to the web server and download HTML
      #
      def get_html(url)
        # Keep track of attempts
        tries = 0

        begin
          # Use ISO-8859-2 as it is a Polish website
          Nokogiri::HTML(open(url), nil, 'ISO-8859-2') 
        rescue Exception => ex
          @logger.warn "Having problems opening the link #{url}. Retrying attempt #{tries}.... \n#{ex.message}\n"
      
          tries += 1
          retry if tries < MAX_NUMBER_OF_TRIES
          nil
        end
      end
  
      def max_channel_id
        # Return the constant in this way because it was easier to test it
        MAX_CHANNEL_ID
      end

      #
      # Prepare the link for a given date and a channel number.
      #
      def link(opts = {})
        opts = { :date        => Time.now.strftime("%Y-%m-%d"),
                 :channel_id  => 'ID'}.merge(opts)             
    
        TV_WP_URL.gsub(/DATE/, opts[:date]).gsub(/ID/, opts[:channel_id].to_s)
      end  
  
      #
      # Create a channel object from a given id. 
      #  
      def channel(channel_id)
        # Prepare the link for a given channel
        channel_link = link(:channel_id => channel_id.to_s)
        doc = get_html(channel_link)
    
        channel_name = doc.css(".com h1").text unless doc.nil?    
        if channel_name == "" || channel_name == nil
          return nil
        else
          return Channel.new(:data_source_channel_id => channel_id, :name => channel_name) 
        end
      end
  
      #
      # This method goes from 1 to MAX_CHANNEL_ID and tries to create a channel,
      # depending if it exists on the server or not
      #  
      def available_channels
        channels = []
        # Check possible channel id numbers
        (1..max_channel_id).each do |id|
          c = channel(id)
      
          if c != "" && c != nil
            channels << c 
            @logger.debug "Got channel id #{c.data_source_channel_id} with name #{c.name}"
          end
        end
        channels
      end
  
      #
      # Parse HTML and try to extract a set of TV programs
      #
      def extract_tv_program(doc)
        programs = []
        doc.css(".program").each_with_index do |program, index|
          # Unfortunately description is stored on another web site
          # so have to do a request for each program
          description = extract_description(doc.css(".more")[index]['href'])
      
          programs << Program.new(       
            :starttime    => program.css(".programL strong").inner_html.clean,
            :duration     => program.css(".programL span").inner_html.clean,
            :name         => program.css(".programR h4 a").inner_html.clean,
            :description  => description,
            :episode      => program.css(".programR .ekipa span strong").inner_html.clean,
            :category     => program.css(".programR .ekipa .nbl").inner_html.clean
          )
        end
        programs
      end  
  
      #
      # For a given program, this method tries to get the description
      # which is stored on another web page
      #
      def extract_description(url)
        # Add domain name to url as it's relative
        doc = get_html(WP_BASE_HTTP_LINK + url)
        return "" if doc.nil? 
    
        description = doc.css("p")
        return "" if description.nil? || description == "" || description[1].nil? || description[1] == ""

        description[1].inner_html.clean
      end
  
      #
      # For a given channel return an array of programs
      #  
      def tv_program(channel, date = nil)
        # Make sure we have a date before 
        date = date || Time.now.strftime("%Y-%m-%d")
        channel_link = link(:date => date, :channel_id => channel.data_source_channel_id)    

        doc = get_html(channel_link)                    
        doc.nil? ? [] : extract_tv_program(doc)
      end
    end
  end
end