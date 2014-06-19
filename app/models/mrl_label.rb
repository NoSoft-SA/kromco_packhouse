class MrlLabel < ActiveRecord::Base

    belongs_to :delivery
    belongs_to :mrl_label_type

end