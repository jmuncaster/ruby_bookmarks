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

puts bc

puts "Merging folders of the same name"
bc.merge_folders

puts "Merging bookmarks of the same name"
bc.merge_bookmarks

puts "Removing empty folders"
bc.remove_empty_folders

puts "Sorting result"
bc.sort!

puts "Saving"
#puts bc
bc.save # Saves the combined bookmarks both Chrome and Safari
