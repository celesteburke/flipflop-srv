#!/usr/bin/env ruby

require 'rss'
require 'feed-normalizer'     

def get_rss_feed
  feeds = ['http://feeds.washingtonpost.com/rss/rss_dc-sports-bog', 
           'http://rss.nytimes.com/services/xml/rss/nyt/Science.xml', 
           'http://feeds.washingtonpost.com/rss/rss_erik-wemple',
           'http://feedproxy.google.com/PetaPixel', 
           'http://rss.cnn.com/rss/cnn_world.rss', 
          ]
  feeds.each do |feed|
    puts "Feed: #{feed}"
    #content = "" # raw content of rss feed will be loaded here
    #open(feed) do |s| content = s.read end
    #content.force_encoding('utf-8')

    rss = FeedNormalizer::FeedNormalizer.parse open(feed)
  end
  
end
