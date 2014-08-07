#!/usr/bin/env ruby

require 'optparse'
require 'ostruct' 
require 'tweetstream'
require 'timeout'
require 'pp' 
require 'active_record'
require 'mysql2'

# Change the following to reflect your database settings
ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     'localhost',
  database: 'rscrape',
  username: 'rscrape',
  password: '8EDvBxBA4TcsS8dp'
)

# Define your classes based on the database, as always
class Tweet < ActiveRecord::Base
end

class RKeywords
  def run
    options = {:num_tweets => 10}
    OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options]"

      opts.on("-n", '--numtweets N', "Number of tweets to grab") do |n|
        options[:num_tweets] = n
      end
    end.parse!

    p options
    p ARGV

    keywords = get_keywords(ARGV[0])
    hashtag_keywords = get_hashtag_keywords(ARGV[1])

    #tweet = Tweet.create(text: "test tweet")
    start_tweet_stream(keywords)

  end

  def get_keywords(keyword_file)
    File.readlines(keyword_file).each {|l| l.chomp!}
  end

  def get_hashtag_keywords(hashtag_keyword_file)
    File.readlines(hashtag_keyword_file).each {|l| l.chomp!}
  end 


  def start_tweet_stream(keywords)
    TweetStream.configure do |config|
      config.consumer_key       = ENV["CONSUMER_KEY"]       
      config.consumer_secret    = ENV["CONSUMER_SECRET"]    
      config.oauth_token        = ENV["ACCESS_TOKEN"]       
      config.oauth_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      config.auth_method        = :oauth
    end


    #begin
      #complete_results = Timeout.timeout(120) do      
    i = 0
    TweetStream::Client.new.track(keywords) do |status, client|
      i += 1
      puts "#{status.text}"
      Tweet.create(text: "#{status.text}")
      client.stop if i >= options[:num_tweets] 
    end
    #end
    #rescue Timeout::Error
    #  puts 'Getting Tweets timed out.'
    #end

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
      tweets = client.search(search_str, :lang => 'EN')
      
      if tweets.count != 0
        puts "==== Search String: #{search_str}"  
        tweets.take(3).collect do |tweet|
          puts "Tweet: #{tweet.text}"
        end
        puts "--------------------------------" 
      end
    end

    search_str = keywords[0, 3].join(" OR ")
    pp search_str
    tweets = client.search(search_str, :lang => 'EN')
      
    if tweets.count != 0
      puts "==== Search String: #{search_str}"  
      tweets.take(3).collect do |tweet|
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
app = RKeywords.new
app.run
