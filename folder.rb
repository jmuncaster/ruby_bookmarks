class Folder
  attr_accessor :children, :name
  def initialize(name)
    @name = name
    @children = []
  end

  def clear
    @children = []
  end

  def contains_url(url)
    @children.each do |child|
      return true if child.respond_to?(:url) && child.url == url
    end
    false
  end

  def contains_folder(name)
    @children.each do |child|
      return true if !child.respond_to?(:url) && child.name == name
    end
    false
  end

  def add_from_folder(folder)
    unless folder.nil?
      folder.children.each do |item|
        if (item.respond_to?(:url)) # we've got a url
          # TODO only checking folder name
          # should compare folder contents as well
          self.children.push(item) # unless self.contains_url item.url
        else # a folder
          self.children.push(item) # unless self.contains_folder item.name
        end
      end
    end
  end

  def add_from_array(arr)
    arr.each do |item|
      if (item.respond_to?(:url)) # we've got a url
        self.children.push(item) #unless self.contains_url item.url
      else # a folder
        self.children.push(item) #unless self.contains_folder item.name
      end
    end
  end
  def all_children(&block)
    @children.each do |item|
      if (item.respond_to?(:date_modified)) # we've got a folder
        item.all_children &block
      else
        yield item
      end
    end
  end

  def remove_empty_folders
    to_remove = []
    @children.each do |item|
      if not item.respond_to?(:url)
        item.remove_empty_folders  # recurse
        to_remove.push item if item.children.empty?
      end
    end
    puts "  Removed #{to_remove.length} folders" if !to_remove.empty?
    @children = @children - to_remove
  end

  def build_folder_hash(folder_hash)
    @children.each do |item|
      if not item.respond_to?(:url)  # Folder?
        folder_hash[item.name] = [] if not folder_hash.keys.include?(item.name)
        folder_hash[item.name].push item
        item.build_folder_hash folder_hash
      end
    end
  end

  def build_bookmarks_hash(bookmark_hash)
    @children.each do |item|
      if item.respond_to?(:url)  # URL?
        key = {:name => item.name, :url => item.url}
        bookmark_hash[key] = [] if not bookmark_hash.keys.include?(key)
        bookmark_hash[key].push self
      else
        item.build_bookmarks_hash bookmark_hash
      end
    end
  end

  def remove_one(name, url)
    last_index = @children.rindex { |child| child.respond_to?(:url) and child.url == url and child.name == name }
    @children.delete_at(last_index)
  end

  def sort!
    @children.sort! do |x,y|
      if x.respond_to?(:url) and not y.respond_to?(:url)
        -1
      elsif y.respond_to?(:url) and not x.respond_to?(:url)
        1
      else
        x.name.casecmp(y.name)
      end
    end

    @children.each do |item|
      item.sort! if not item.respond_to?(:url)
    end
  end

  def to_s(indent=0)
    #puts "In Folder::to_s. I have #{@children.length} children."
    spaces = " " * indent
    strings = ["#{spaces}#{@name}/  (#{@children.length} children)"]
    @children.each do |child|
      strings.push(child.to_s(indent + 2))
    end
    strings.join("\n")
  end

end
