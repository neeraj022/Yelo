class Statistic
  include Mongoid::Document

  field: tag_count,      type: Integer, default: 0
  field: up_votes,       type: Integer, default: 0
  field: rating_avg,     type: Integer, default: 0
  field: rating_score,   type: Integer, default: 0

  embedded_in :user
end
