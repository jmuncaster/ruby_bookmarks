class Bookmark
  attr_accessor :url, :name
  def initialize(name, url)
    @name = name
    @url = url
  end

  def to_s(indent=0)
    #puts "In Bookmark::to_s"
    spaces = " " * indent
    "#{spaces}#{@name} | #{url}"
  end
end
