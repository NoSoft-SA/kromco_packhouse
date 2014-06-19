class RebinTemplate < ActiveRecord::Base
  belongs_to :rebin_setup
  has_many :rebin_links,:dependent => :destroy
end
