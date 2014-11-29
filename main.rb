require './util'
require './bookmark'
require './folder'
require './bookmarkcollection'

require './chrome'
require './safari'

include Chrome
include Safari

#bc = BookmarkCollection.new([ChromeProvider.new, SafariProvider.new])
bc = BookmarkCollection.new([SafariProvider.new])
bc.load # Loads in all bookmarks from Safari & Chrome

#bc.bookmarks_bar.each do |item|
#    #iterates through the bookmark bar
#end

#bc.other.each do |item|
#  #iterates through the other bookmarks
#end

#bc.all do |item|
#  puts item.to_s
#end

puts "Removing empty folders"
bc.remove_empty_folders

puts "Saving"
#puts bc
bc.save # Saves the combined bookmarks both Chrome and Safari
