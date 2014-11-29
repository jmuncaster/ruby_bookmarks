require 'cfpropertylist'

module Safari
  class SafariProvider

    def debug_print_root(data)
      puts "Examining root node"
      puts "  Fields:"
      data.keys.each do |key|
        puts "    #{key}"
      end

      puts "  Root children:"
      root_children = data["Children"]
      root_children.each do |root|
        type = root["WebBookmarkType"]
        if type.eql? "WebBookmarkTypeLeaf"
          name = root["URIDictionary"]["title"]
        else
          name = root["Title"]
        end
        puts "    #{name}  (#{root["WebBookmarkType"]})"
      end
    end

    def load(filename='~/Library/Safari/Bookmarks.plist')

      if filename.include? '~'
        filename.gsub!('~', ENV["HOME"])
      end
      plist = CFPropertyList::List.new(:file => filename)
      data = CFPropertyList.native_types(plist.value)

      self.debug_print_root data

      puts "Parsing bookmarks"

      @original = data
      puts "  There are #{data['Children'].length} children"

      all = data["Children"].dup

      # Note special nodes: History and BookmarksBar
      @history_node = all[0]
      if not @history_node["Title"].eql? "History"
        puts "  WARNING: First node title is #{bookmarks_node['Title']}, not BookmarksBar"
      end
      bookmarks_bar_node = all[1]
      if not bookmarks_bar_node["Title"].eql? "BookmarksBar"
        puts "  WARNING: First node title is #{bookmarks_node['Title']}, not BookmarksBar"
      end

      # Note other special nodes
      @reserved_nodes = []
      reserved_titles = []
      reserved_list = ["Address Book", "Bonjour", "All RSS Feeds", "BookmarksMenu"]
      all.each do |item|
        title = item["Title"]
        if reserved_list.include?(title)
          puts "  Adding #{title} to reserved nodes list"
          @reserved_nodes.push(item)
          reserved_titles.push(title)
        end
      end

      # Note remaining nodes (all except reserved nodes)
      other_nodes = all - [@history_node] - [bookmarks_bar_node] - @reserved_nodes

      puts "  Found 1 history node: #{[@history_node['Title']].to_s}"
      puts "  Found 1 bookmarks bar node: #{[bookmarks_bar_node['Title']].to_s}"
      puts "  Found #{@reserved_nodes.length} reserved nodes: #{reserved_titles.to_s}"
      puts "  Found #{other_nodes.length} other nodes"

      # Create data structure for bookmarks bar
      bookmarks_bar = SafariFolder.new_from_hash(bookmarks_bar_node)

      # Create data structure for everything else
      other_root = Folder.new("Other Bookmarks")
      other_bookmarks = []
      other_nodes.each do |node|
        if node["WebBookmarkType"] == "WebBookmarkTypeLeaf"
          other_bookmarks.push(SafariBookmark.new_from_hash(node))
        else
          other_bookmarks.push(SafariFolder.new_from_hash(node))
        end
      end
     other_root.add_from_array other_bookmarks

      return {"bar" => bookmarks_bar, "other" => other_root}
    end

    def save(collection, dry_run, filename='~/Library/Safari/Bookmarks.plist')

      if filename.include? '~'
        filename.gsub!('~', ENV["HOME"])
      end

      # Get all keys/values of root node.
      outline = @original.dup

      # Remove all children - we will rebuild.
      outline["Children"] = []

      # 0th node is actually History
      outline["Children"].push @history_node

      # First, as per Safari's preference - Add BookmarksBar
      outline["Children"].push folder_to_hash(collection.bookmarks_bar)

      # Second, once again like Safari likes - Add reserved nodes
      @reserved_nodes.each do |item|
        outline["Children"].push item
      end

      # Last, add all other children
      collection.other.children.each do |item|
        if item.respond_to?(:url)
          outline["Children"].push(bookmark_to_hash(item))
        else
          outline["Children"].push(folder_to_hash(item))
        end
      end

      # Debug
      puts "  There are #{outline['Children'].length} children."

      # Create plist
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(outline) # data is native ruby structure

      puts "(skipped save to Safari - dry run)" if dry_run
      plist.save(filename, CFPropertyList::List::FORMAT_BINARY) unless dry_run
    end

    private

    def folder_to_hash(folder)
      ret = Hash.new
      if folder.name =="bookmarks_bar"
        folder.name = "BookmarksBar"
      end
      ret["Title"] = folder.name
      ret["WebBookmarkType"] = "WebBookmarkTypeList"
      ret["WebBookmarkUUID"] = folder.respond_to?(:uuid) ? folder.uuid : Apple.new_uuid
      children = Array.new
      folder.children.each do |item|
        if item.respond_to?(:url)
          children.push(bookmark_to_hash(item))
        else
          children.push(folder_to_hash(item))
        end
      end
      ret["Children"] = children
      ret
    end

    def bookmark_to_hash(bookmark)
      return {"URIDictionary" => {"title" => bookmark.name},
      "URLString" => bookmark.url, "WebBookmarkType" => "WebBookmarkTypeLeaf", "WebBookmarkUUID" => (bookmark.respond_to?(:uuid) and bookmark.uuid) ? bookmark.uuid : Apple.new_uuid}
    end

    def bookmark_to_cache_hash(bookmark)
      return { "Name" => bookmark.name, "URL" => bookmark.url }
    end
  end

  class SafariBookmark < Bookmark
    attr_accessor :uuid

    def initialize(name, url, uuid)
      @uuid = uuid
      super(name, url)
    end

    def SafariBookmark.new_from_hash(hash)
      return self.new(hash["URIDictionary"]["title"], hash["URLString"], hash["WebBookmakUUID"])
    end
  end

  class SafariFolder < Folder
    attr_accessor :uuid

    def initialize(name, uuid)
      @uuid = uuid
      super(name)
    end

    def SafariFolder.new_from_hash(hash)
      folder = self.new(hash["Title"], hash["WebBookmarkUUID"])
      if hash["Children"]
        hash["Children"].each do |item|
          if item["WebBookmarkType"] == "WebBookmarkTypeList"
            folder.children.push(self.new_from_hash(item))
          elsif item["WebBookmarkType"] == "WebBookmarkTypeLeaf"
            folder.children.push(SafariBookmark.new_from_hash(item))
          else
            puts "Unknown item: #{item}"
          end
        end
      end
      return folder
    end
  end
end
