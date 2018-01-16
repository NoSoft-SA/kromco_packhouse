class DeliveryTrackIndicator < ActiveRecord::Base
  attr_accessor :variety_type, :starch_summary_results

  belongs_to :delivery
  belongs_to :track_slms_indicator

  validates_presence_of :track_indicator_type_code, :track_slms_indicator_code, :commodity_code, :season_code, :rmt_variety_code
  #validates_uniqueness_of :track_indicator_type_code

  def DeliveryTrackIndicator.add_delivery_track_indicator_to_bins(delivery, delivery_track_indicator, user_name)
    if (b=delivery.bins[0])
      # (1..5).each do |g|
      #   if (!eval("b.track_indicator#{g}_id"))
          or_clause = "bins.bin_number='#{delivery.bins.map { |bn| bn.bin_number }.join("' or bins.bin_number='")}'"
          if(delivery_track_indicator.track_indicator_type_code == 'RMI')
            g = 1
          elsif(delivery_track_indicator.track_indicator_type_code == 'STA')
            g = 2
          elsif(delivery_track_indicator.track_indicator_type_code == 'pressure_ripeness')
            g = 3
          end
          ActiveRecord::Base.connection.execute("update bins set track_indicator#{g}_id=#{delivery_track_indicator.track_slms_indicator_id} where #{or_clause}")

          LogDataChange.create!(:user_name => user_name,
                                :ref_nos => "Delivery Number=#{delivery.delivery_number} , Track Indicator=#{delivery_track_indicator.track_slms_indicator_id}",
                                :notes => "#{delivery.bins.map { |bn| bn.bin_number }.join(",")}",
                                :type_of_change => 'ADD TRACK INDICATOR TO A LIST OF BINS')
          # break
        # end
      # end
    end
  end

  def DeliveryTrackIndicator.delete_delivery_track_indicator_from_bins(delivery_track_indicator, delivery, user_name)
    if ((b=delivery.bins[0]) && delivery_track_indicator_to_be_removed = {:track_indicator1_id => b.track_indicator1_id, :track_indicator2_id => b.track_indicator2_id,
                                                                          :track_indicator3_id => b.track_indicator3_id, :track_indicator4_id => b.track_indicator4_id,
                                                                          :track_indicator5_id => b.track_indicator5_id}.select { |k, v| v==delivery_track_indicator.track_slms_indicator_id })

      or_clause = "bins.bin_number='#{delivery.bins.map { |bn| bn.bin_number }.join("' or bins.bin_number='")}'"
      ActiveRecord::Base.connection.execute("update bins set #{delivery_track_indicator_to_be_removed[0][0]}=null where #{or_clause}")

      LogDataChange.create!(:user_name => user_name,
                            :ref_nos => "Delivery Number=#{delivery.delivery_number} , Track Indicator=#{delivery_track_indicator.track_slms_indicator_id}",
                            :notes => "#{delivery.bins.map { |bn| bn.bin_number }.join(",")}",
                            :type_of_change => 'REMOVE TRACK INDICATOR FROM A LIST OF BINS')

    end
  end

end