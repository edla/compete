# Copyright (c) 2008 Ed Laczynski
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# The design pattern for this API plugin was adapted from voxxit's DirectAdmin plugin c/a Joshua Delsman, Voxxit, LLC Thanks Josh!

module Compete #:nodoc:
  class MissingInformationError < StandardError; end #:nodoc:
  class CompeteError < StandardError; end #:nodoc:

  # Provides access to Compete's API
  # More information on the API can be found here: http://developer.compete.com/
  class Base

    VERSION = "0.1"
    
	  # Defines the required parameters to interface with Compete
  	REQUIRED_OPTIONS = {:base   => [:compete_api_key],
  	                    :do     => [:url]}

  	attr_accessor :compete_api_key
              
  	# Initializes the Compete::Base class, setting defaults where necessary.
    # 
    #  da = Compete::Base.new(options = {})
    #
    # === Example:
    #   da = Compete::Base.new(:compete_api_key      => COMPETE_API_KEY)
    #
    # === Required options for new
    #   :compete_api_key       - Your Compete.com API key
  	def initialize(options = {})
  	  check_required_options(:base, options)

  	  @compete_api_key	= options[:compete_api_key]

  	end
                  
    def do(options={})
      
       check_required_options(:do, options)
       url = options[:url]
       size = options[:size] || "large"
       
      
       uri = URI.parse(

                 "http://api.compete.com/fast-cgi/MI?" +
                 {
                   "d"       => url,
                   "ver"  => "3",
                   "apikey"       => @compete_api_key,
                   "size"       => size
                 }.to_a.collect{|item| item.first + "=" + CGI::escape(item.last) }.join("&") # Put key value pairs into http GET format
              )

       xml  = REXML::Document.new( Net::HTTP.get(uri) )
       return xml
     end
     
     	# Used to parse the XML response into a Compete specific hash, if one would like.
      # Retreives the latest stats available from the Compete XML response
      #
     	# === Example
     	#   @compete_info = @compete.parse(compete_xml)
     	#
     	# === Result
     	#   {:rank=>"1", :uv_ranking=>"1", :uv_count=>"135,834,459", :month=>"06", :year=>"2008", :domain=>"google.com"}
     	def parse(xml)
         info = Hash.new { |h,k| h[k] = "" }

         info[:domain] << xml.elements["//ci/dmn/nm"][0].to_s.strip
         info[:rank] <<  xml.elements["//ci/dmn/rank/val"][0].to_s.strip
         info[:month] <<  xml.elements["//ci/dmn/metrics/val/mth"][0].to_s.strip 
         info[:year] <<  xml.elements["//ci/dmn/metrics/val/yr"][0].to_s.strip 
         info[:uv_ranking] <<  xml.elements["//ci/dmn/metrics/val/uv/ranking"][0].to_s.strip 
         info[:uv_count] <<  xml.elements["//ci/dmn/metrics/val/uv/count"][0].to_s.strip 


         return info
   	  end
   	  
   	                  
    private
       # Checks the supplied options for a given method or field and throws an exception if anything is missing
       def check_required_options(option_set_name, options = {})
         required_options = REQUIRED_OPTIONS[option_set_name]
         missing = []
         required_options.each{|option| missing << option if options[option].nil?}

         unless missing.empty?
           raise MissingInformationError.new("Missing #{missing.collect{|m| ":#{m}"}.join(', ')}")
         end
       end
    end
end
