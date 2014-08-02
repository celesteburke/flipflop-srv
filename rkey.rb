#!/usr/bin/env ruby

require 'optparse'
require 'date' 
require 'ostruct' 
require 'net/http'
require 'uri'
require 'net/http'
require 'rubygems'
require 'fast_stemmer'
require 'pismo'
require 'pp' 
require 'twitter' 

class RKeywords

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @verbose = false
  end


  def parse_options(argv)
    params = {}
    parser = OptionParser.new 

    parser.on("-t") { params[:title_text] = true }

    files = parser.parse(argv)

    [params, files]
  end

  def arguments_valid
    return true
  end

  def run
    if arguments_valid
      output_options if @options.verbose # [Optional]
      
      cmd_line = parse_options(ARGV)
      
      #puts "params are #{cmd_line[0].inspect}"
      #puts "files are #{cmd_line[1].inspect}"
      
      # Get web page 
      response = get_url(cmd_line[1][0])

      # Page contents are available in response.body 
      #puts "Content Type: " + response.content_type
      get_encoding(response["content-type"])
      body_text = get_body_text(response.body)
      title_text = get_title_text(response.body)
      stop_words = get_stop_words

      doc = Pismo::Document.new(cmd_line[1][0])

      puts "title: " + doc.title
      pp doc.keywords[0,5]
      
      # Remove any stop words first & get tweets
      get_tweets((doc.keywords.map{|row| row[0]} - stop_words)[0,5])
      
    else
      puts "Couldn't parse options, die!"
    end
    
  end

  def get_tweets(keywords)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["CONSUMER_KEY"]
      config.consumer_secret     = ENV["CONSUMER_SECRET"]
      config.access_token        = ENV["ACCESS_TOKEN"]
      config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
    end

    keywords.each do |keyword|
      search_str = "##{keyword}"
      puts "==== Search String: #{search_str}"
      client.search(search_str, :lang => 'EN').take(3).collect do |tweet|
        puts "Tweet: #{tweet.text}"
      end
      puts "--------------------------------" 
    end
  end
  def get_title_keywords(title_text)
    puts "\n=== Title Keywords ===\n"
  end

  def get_stop_words
    stop_words = File.readlines('stop_words.out.txt').each {|l| l.chomp!}
    # Testing stemmer by stemming stop words list
    #stop_words.each { |x| puts x.stem }
  end

  def get_body_text(html)
    # options m:dot matches newline 
    # i: insensitive
    # u: force UTF8 for pattern & string
    /<body[^>]*?>.*?<\/body>/miu =~ html.force_encoding('iso-8859-1').encode('utf-8') 
    return $&
  end

  def get_title_text(html)
    # options m:dot matches newline 
    # i: insensitive
    # u: force UTF8 for pattern & string
    /<title[^>]*?>.*?<\/title>/miu =~ html.force_encoding('iso-8859-1').encode('utf-8') 
    return $&
  end

  def get_encoding(header)
    /charset=(.*)/ =~ header
    puts "Encoding: " + $~[1]
  end

  def output_options
    puts "Options:\n"
    @options.marshal_dump.each do |name, val|        
      puts "  #{name} = #{val}"
    end
  end

  def get_url(url)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
  end
end

# Create and run the application
app = RKeywords.new(ARGV, STDIN)
app.run
