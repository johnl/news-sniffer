#!/usr/bin/ruby 
#
require File.dirname(__FILE__) + '/config/environment'

good = {}
bad = {}
STDERR.write "Training bad..."
HysComment.find(:all, :conditions => 'censored = 0', :limit => 1000).each do |c|
  STDERR.write "."
  text = c.text.gsub(/[^a-z0-9]/i,' ').downcase
  text = text.gsub(/<[^>]+>/i,' ')
  text.split(' ').each do |word|
    bad[word] = 0 unless bad.has_key? word
    bad[word] += 1
  end
  
end
STDERR.write "\n"


STDERR.write "Training good..."
HysComment.find(:all, :conditions => 'censored = 1', :limit => 3000).each do |c|
  STDERR.write "."
  text = c.text.gsub(/[^a-z0-9]/i,' ').downcase
  text = text.gsub(/<[^>]+>/i,' ')
  text.split(' ').each do |word|
    good[word] = 0 unless good.has_key? word
    good[word] += 1
  end
end
STDERR.write "\n"

#good.each do |word,count|
#  if bad.has_key?(word)
#    good.delete word
#    bad.delete word
#  end
#end
#

dead_words = %w{to and of a br i is in it that there them our the be have are they with on as you me we this not was will a all my but his her people their can at so should if by who what has from do   }
dead_words.each { |word| bad.delete(word) ; good.delete(word) }

bad_words = bad.sort {|a,b| a[1] <=> b[1]}.reverse
good_words = good.sort {|a,b| a[1] <=> b[1]}.reverse


puts "bad words"
bad_words[1..100].each { |word,count| puts "#{count}\t#{word}" }
puts "good words"
good_words[1..100].each { |word,count| puts "#{count}\t#{word}" }

