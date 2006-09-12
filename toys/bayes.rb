#!/usr/bin/ruby 
#
require File.dirname(__FILE__) + '/config/environment'
require 'bishop'

classifier = Bishop::Bayes.new { |probs,ignore| Bishop::robinson( probs, ignore ) }

classifier.load "bayes.yaml"

while true do 
  begin
    text = readline
  rescue EOFError
    break
  end
  puts classifier.guess(text)
end

exit


classifier = Bishop::Bayes.new { |probs,ignore| Bishop::robinson( probs, ignore ) }
STDERR.write "Training bad..."
HysComment.find(:all, :conditions => 'censored = 0', :limit => 1000).each do |c|
  classifier.train( "bad", c.text )
  STDERR.write "."
end
STDERR.write "\n"


STDERR.write "Training good..."
HysComment.find(:all, :conditions => 'censored = 1', :limit => 30000).each do |c|
  classifier.train( "good", c.text )
  STDERR.write "."
end
STDERR.write "\n"

classifier.save "bayes.yaml"
