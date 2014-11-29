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
