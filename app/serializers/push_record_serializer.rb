class PushRecordSerializer < CustomSerializer
  # attributes :id, :user_id, :n_status, :n_value, :n_type
  attributes :n_id, :user_id, :key, :w_id, :tag, :alert, :dt

  def n_id
    "#{object.id.to_s}"
  end

  def w_id
    "#{object.wall_id.to_s}"
  end

  def tag
    "#{object.tag_name}"
  end

  def key
    "#{object.n_type}"
  end

  def alert
    "#{object.message}"
  end

  def dt
    "#{object.created_at.strftime('%Y-%m-%d %H:%M:%S %z')}"
  end

end
