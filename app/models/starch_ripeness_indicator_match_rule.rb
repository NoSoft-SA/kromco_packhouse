class StarchRipenessIndicatorMatchRule < ActiveRecord::Base

  validates_presence_of :rmt_variety_id,:opt_cat_count,:pre_opt_cat_count,:post_opt_cat_count,:match_ripeness_indicator_id
  belongs_to :rmt_variety
  has_many :track_slms_indicators

  def validate
    check_for_equal_sign
    # is_valid = validate_equal_sign?
    # if self.new_record? && is_valid
    #   validate_uniqueness
    # end
  end

  def validate_uniqueness

  end

  def before_save

  end

  def after_destroy

  end

  def check_for_equal_sign
    # s = 'x = y and y <= 9 and z >= 2 and m == 1'
    # y = s.gsub(/ and /i, ' && ').gsub(/ or /i, ' || ').gsub(/ = /i, ' == ') if s.gsub('==', '##').gsub('>=', '##').gsub('<=', '##').include?('=')
    self.pre_opt_cat_count = validate_equal_sign(self.pre_opt_cat_count)
    self.opt_cat_count = validate_equal_sign(self.opt_cat_count)
    self.post_opt_cat_count = validate_equal_sign(self.post_opt_cat_count)
  end

  def validate_equal_sign(num)
    if num.gsub('==', '##').gsub('>=', '##').gsub('<=', '##').gsub('!=', '##').include?('=')
      num = num.gsub('==', 'equals').gsub('>=', 'greater').gsub('<=', 'less').gsub('!=', 'not equal')
      num = num.gsub(/=/i, ' == ')
      num = num.gsub('equals', '==').gsub('greater', '>=').gsub('less', '<=').gsub('not equal', '!=')
      # num = num.gsub(/ and /i, ' && ').gsub(/ or /i, ' || ').gsub(/ = /i, ' == ')
    end
    return num
  end

  def self.summation(sum)
    combinations = []
    for x in 0..(sum)
      for y in 0..(sum)
        z = (sum - (x + y))
        # combinations << "#{i},#{j},#{diff}" if diff >= 0
        combinations << [x,y,z] if z >= 0
      end
    end
    return combinations
  end

end