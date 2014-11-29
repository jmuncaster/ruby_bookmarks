class BookmarkCollection
  attr_accessor :bookmarks_bar, :other, :providers

  def initialize(providers)
    @bookmarks_bar = Folder.new("bookmarks_bar")
    @other = Folder.new("Other Bookmarks")
    @providers = providers
  end

  def load
    @providers.each do |provider|
      res = provider.load
      @bookmarks_bar.add_from_folder res["bar"]
      @other.add_from_folder res["other"]
    end
  end

  def save
    @providers.each do |provider|
      provider.save(self)
    end
  end

  def all(&block)
    @bookmarks_bar.all_children &block
    @other.all_children &block
  end

  def remove_empty_folders
    @bookmarks_bar.remove_empty_folders
    @other.remove_empty_folders
  end

  def build_folder_hash
    folder_hash = {}
    @bookmarks_bar.build_folder_hash folder_hash
    @other.build_folder_hash folder_hash

    dups_folder_hash = {}
    folder_hash.keys.each do |key|
      if folder_hash[key].length > 1
        dups_folder_hash[key] = folder_hash[key]
      end
    end

    puts "  Duplicate folders:" unless dups_folder_hash.empty?
    dups_folder_hash.keys.each do |key|
      puts "  #{key}: #{dups_folder_hash[key].length} dups"
    end

    @folder_hash = dups_folder_hash

  end

  def merge_folders
    self.build_folder_hash

    puts "  Merging folders" unless @folder_hash.empty?

    @folder_hash.keys.each do |name|
      folders = @folder_hash[name]

      if folders.length > 1
        puts "  Merging #{name}"
        merged = folders[0]
        others = folders.slice(1, folders.length - 1)

        others.each do |other|
          puts "    Adding #{other.children.length} items."
          merged.add_from_array other.children
          other.clear
        end

        puts "  Merged #{name}. Contains #{merged.children.length} items."
      end
    end

    self.build_folder_hash
  end

  def to_s
    @bookmarks_bar.to_s + "\n" + @other.to_s
  end
end
