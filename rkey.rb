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
require_relative 'rss_functions' 
require 'tweetstream'
require 'timeout'

class RKeywords

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @verbose = false
  end

  def run
    if ARGV.count == 2
      feeds = File.readlines(ARGV[0]).each {|l| l.chomp!}
      keywords = []
      hashtag_keywords = []
      feeds_key_file = File.open("rss_with_keywords.out.txt", "w+")
      
      # Take 5 entries per feed and get keywords from them
      # Output the keywords to files
      feeds.each do |feed|
        rss = FeedNormalizer::FeedNormalizer.parse open(feed)
        rss.entries.take(5).each do |entry|
          stop_words = get_stop_words

          doc = Pismo::Document.new(entry.url)
          puts "title: #{doc.title}"
          feeds_key_file.puts("title: #{doc.title}")
          feeds_key_file.puts((doc.keywords.map{|row| row[0]} - stop_words)[0,5])

          # Remove any stop words & append to keywords array
          (doc.keywords.map{|row| row[0]} - stop_words).take(5).each do |keyword|
            keywords << keyword
          end
        end  
      end

      feeds_key_file.close()

      File.open("keywords.out.txt", "w+") do |f|
        keywords.uniq.each { |element| f.puts(element) }
      end
    else
      puts "rkey.rb: missing file argument"
      puts "Usage:  rkey.rb [rssfeeds.txt] [stop_words.txt]"
    end
    
  end
  def get_stop_words
    stop_words = File.readlines(ARGV[1]).each {|l| l.chomp!}
    # Testing stemmer by stemming stop words list
    #stop_words.each { |x| puts x.stem }
  end
end

# Create and run the application
app = RKeywords.new(ARGV, STDIN)
app.run
