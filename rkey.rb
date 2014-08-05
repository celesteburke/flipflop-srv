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
      
      feeds = File.readlines('rssfeeds.txt').each {|l| l.chomp!}
      keywords = []
      hashtag_keywords = []

      # Take 5 entries per feed and get keywords from them
      # Output the keywords and hashtags to files
      feeds.each do |feed|
        rss = FeedNormalizer::FeedNormalizer.parse open(feed)
        rss.entries.take(5).each do |entry|
          stop_words = get_stop_words

          doc = Pismo::Document.new(entry.url)
          puts "title: #{doc.title}"
          
          # Remove any stop words & append to keywords & hashtags arrays 
          (doc.keywords.map{|row| row[0]} - stop_words).take(5).each do |keyword|
            keywords << keyword
            hashtag_keywords << "##{keyword}"
          end
        end  
      end

      File.open("keywords.out.txt", "w+") do |f|
        keywords.uniq.each { |element| f.puts(element) }
      end

      File.open("keywords.hashtags.out.txt", "w+") do |f|
        hashtag_keywords.uniq.each { |element| f.puts(element) }
      end

    else
      puts "Couldn't parse options, die!"
    end
    
  end
  def get_stop_words
    stop_words = File.readlines('stop_words.out.txt').each {|l| l.chomp!}
    # Testing stemmer by stemming stop words list
    #stop_words.each { |x| puts x.stem }
  end

  def output_options
    puts "Options:\n"
    @options.marshal_dump.each do |name, val|        
      puts "  #{name} = #{val}"
    end
  end
end

# Create and run the application
app = RKeywords.new(ARGV, STDIN)
app.run
