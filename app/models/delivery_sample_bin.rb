class DeliverySampleBin < ActiveRecord::Base

    belongs_to :delivery
    has_many :delivery_sample_bins

end