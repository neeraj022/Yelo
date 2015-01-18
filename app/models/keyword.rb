class Keyword
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :tag_id,     type: BSON::ObjectId
  field :name,       type: String
  field :word_id,    type: BSON::ObjectId
  field :synonyms,   type: Array
  ####### relations ####################
  belongs_to :tag
  ####### filters ######################
  before_save :save_format_word
  ####### validation ###################
  validates :tag_id, :name, presence: true
  validate :word_uniqueness
  ####### instance methods #############
  def word_uniqueness
    w_presence = Keyword.where(tag_id: tag_id, name: name).first
    if(w_presence.present?)
      errors.add(:base, "The keyword already exists")
    end
  end
   
  def save_format_word
    self.name = Keyword.format_word(self.name)
  end

  ##########  class methods ###################
  def self.format_word(word)
    word.downcase.gsub(/\s+/, "-")
  end

end
