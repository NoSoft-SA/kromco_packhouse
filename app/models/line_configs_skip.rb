class LineConfigsSkip < ActiveRecord::Base
    belongs_to :line_config
    belongs_to :skip
end