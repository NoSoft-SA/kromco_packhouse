class StarchRipenessIndicatorMatchRule < ActiveRecord::Base

  validates_presence_of :rmt_variety_id,:opt_cat_count,:pre_opt_cat_count,:post_opt_cat_count,:match_ripeness_indicator_id
  belongs_to :rmt_variety
  has_many :track_slms_indicators

  def validate
    # if self.new_record?
    #   validate_uniqueness
    # end
  end

  def validate_uniqueness

  end

  def before_save

  end

  def after_destroy

  end

end