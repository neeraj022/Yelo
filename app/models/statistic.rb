class Statistic
  include Mongoid::Document

  field :tag_count,       type: Integer,  default: 0
  field :up_votes,        type: Integer,  default: 0
  field :rating_avg,      type: Integer,  default: 0
  field :rating_score,    type: Integer,  default: 0
  field :last_post,       type: DateTime, default: 0
  field :tdy_pst_cnt,     type: Integer,  default: 0
  field :last_sms_sent,   type: DateTime
  field :sms_count,       type: Integer, default: 0
  field :connects,        type: Integer, default: 0
  ################## relations ####################
  embedded_in :user
end
