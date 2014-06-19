class RebinLabelSetup < ActiveRecord::Base
 belongs_to :label
 belongs_to :rebin_setup
 has_many :rebin_links,:dependent => :destroy
end
