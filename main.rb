require './util'
require './bookmark'
require './folder'
require './bookmarkcollection'

require './chrome'
require './safari'

include Chrome
include Safari

bc = BookmarkCollection.new([SafariProvider.new, ChromeProvider.new])

# Load bookmarks from the first provider
bc.load_first

puts "Merging folders of the same name"
bc.merge_folders

puts "Merging bookmarks of the same name"
bc.merge_bookmarks

puts "Removing empty folders"
bc.remove_empty_folders

puts "Sorting result"
bc.sort!

puts "Saving"
dry_run = true
bc.save dry_run
