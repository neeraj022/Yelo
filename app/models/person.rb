require 'digest/md5'
class Person
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  
  field :user_id,    type: BSON::ObjectId
  field :h_m_num,    type: BSON::ObjectId
  field :is_present, type: Boolean, default: false

  index "h_m_num" => 1

  attr_accessor :mobile_number

  validates :h_m_num, presence: true, uniqueness: true

  before_validation :hash_mobile_number
  
  def hash_number
  	m_num = Person.get_number(self.mobile_number)
    return nil unless m_num =~ /\A[0-9]{10}\z/
    m_num
  end

  def hash_mobile_number
  	return if self.mobile_number.blank?
  	return (self.h_m_num = nil) unless self.hash_number.present?
    self.h_m_num = Digest::MD5.hexdigest(self.hash_number)
  end

  def self.search(num)
  	num = self.get_number_digest(num)
    self.where(h_m_num: num).first
  end

  def self.get_number_digest(num)
     m_num = self.get_number(num)
    return "" unless m_num =~ /\A[0-9]{10}\z/
    Digest::MD5.hexdigest(m_num)
  end

  def self.get_number(num)
    num = User.mobile_number_format(num)
    num[:mobile_number]
  end

  def self.save_person(num, user_id =nil, presence=nil)
  	h_num = self.get_number_digest(num)
    person = Person.where(h_m_num: h_num).first_or_initialize
    person.is_present = presence if presence.present?
    person.user_id = user_id if user_id.present?
    person.save
    person
  end

end
