class Post < ActiveRecord::Base
  validates_presence_of :content
  # not more content then 1MB
  validates_length_of :content, :maximum => 104875
  validates_length_of :title, :maximum => 255
  validates_length_of :author, :maximum => 255
  attr_accessible :content, :title, :author

  has_many :comments, :dependent => :destroy
  has_one :child, :class_name => "Post",
    :foreign_key => :parent_id, :dependent => :destroy
  belongs_to :parent, :class_name => "Post", :dependent => :destroy

  def self.feed(last)
    self.includes(:comments)
      .where("created_at < ? ", last).where(:newest => true)
      .order('created_at desc').limit(20)
  end

  def collect_parent_ids
    if parent.nil?
      return []
    else
      return [ parent_id ] +  parent.collect_parent_ids
    end
  end

  def all_comments
    Comment.where(:post_id => self.collect_parent_ids).order('created_at desc')
  end

  def create_version(params)
    child = self.class.new(params)
    child.parent_id = self.id
    self.newest = false
    self.save
    return child
  end

  def errors=(errors)
    @errors = errors
  end

  def self.search(search_string)
    return [] if search_string.blank?
    post_arel_table = Post.arel_table
    self.where(
      post_arel_table[:content].matches("%#{search_string}%").or(
      post_arel_table[:title].matches("%#{search_string}%")).or(
      post_arel_table[:author].matches("%#{search_string}%"))).
      order('created_at desc')
  end
end
