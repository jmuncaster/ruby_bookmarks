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
    @folder_hash = {}
    @bookmarks_bar.build_folder_hash @folder_hash
    @other.build_folder_hash @folder_hash

    puts "  Duplicate folders:"
    @folder_hash.keys.each do |key|
      puts "  #{key}: #{@folder_hash[key].length} dups" unless @folder_hash[key].length == 1
    end
  end

  def merge_folders
    puts "  Merging folders"
    @folder_hash.keys.each do |name|
      puts "  Merging #{name}"

      folders = @folder_hash[name]

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

  def to_s
    @bookmarks_bar.to_s + "\n" + @other.to_s
  end
end
