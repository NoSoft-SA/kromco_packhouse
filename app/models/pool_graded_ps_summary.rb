class PoolGradedPsSummary < ActiveRecord::Base

  has_many   :pool_graded_ps_farms, :dependent => :destroy
  has_many   :pool_graded_ps_bins, :dependent => :destroy

  def   self.create_from( ps_lot_number,refresh=nil )
    pool_graded_ps_summary=nil
    pool_graded_ps_farms=nil
    ActiveRecord::Base.transaction do
      if refresh
         delete_pool_graded_ps_summary(ps_lot_number)
      end
    pool_graded_ps_summary=create_pool_graded_ps_summary( ps_lot_number )
    pool_graded_ps_farms=create_pool_graded_ps_farms(ps_lot_number,pool_graded_ps_summary)
    end
    if pool_graded_ps_summary
      return pool_graded_ps_summary ,pool_graded_ps_farms
    else
      return []
    end

  end

  def self.delete_pool_graded_ps_summary(ps_lot_number)
    pool_graded_ps_summary=PoolGradedPsSummary.find_by_maf_lot_number(ps_lot_number)
    pool_graded_ps_summary.destroy  if   pool_graded_ps_summary
  end

  def  self.create_pool_graded_ps_summary( ps_lot_number )
    query = "select count(bins.*) as rmt_bin_count,SUM(bins.weight) as rmt_bin_weight,bins.season_code,rmt_products.commodity_code
             from bins
             inner join rmt_products on bins.rmt_product_id =rmt_products.id
            where bins.ps_tipped_lot_no = '#{ps_lot_number}' group by bins.season_code,rmt_products.commodity_code"
    bins = self.connection.select_all(query)
    pool_graded_ps_summary=nil
    if !bins.empty?
    pool_graded_ps_summary = PoolGradedPsSummary.new(
        :maf_lot_number    => ps_lot_number,
        :season_code       => bins[0].season_code,
        :commodity_code    => bins[0].commodity_code,
        :rmt_bin_count     => bins[0].rmt_bin_count,
        :rmt_bin_weight    => bins[0].rmt_bin_weight,
        :status            => "UNGRADED",
        :created_by        => ActiveRequest.get_active_request.user,
        :updated_by        => ActiveRequest.get_active_request.user
    )
    end
    return   pool_graded_ps_summary
  end

  def self.create_pool_graded_ps_farms(ps_lot_number,pool_graded_ps_summary=nil)
    query = "select count(bins.*) as bin_count,SUM(bins.weight) as bin_mass,farm_id,farms.farm_code,track_slms_indicators.track_slms_indicator_code
              from bins
              inner join farms on bins.farm_id=farms.id
              inner join track_slms_indicators on bins.track_indicator1_id=track_slms_indicators.id
               where bins.ps_tipped_lot_no = '#{ps_lot_number}' group by farm_id,farms.farm_code,track_slms_indicators.track_slms_indicator_code"
    bins = self.connection.select_all(query)
    pool_graded_ps_farms=[]
    if !bins.empty?
      bins.each do |bin|
        pro_rata_factor = sprintf('%0.2f',pool_graded_ps_summary.rmt_bin_weight/bin.bin_mass ).to_f
      pool_graded_ps_farm = PoolGradedPsFarm.new(
          #:pool_graded_ps_summary_id    => pool_graded_ps_summary_id,
          :farm_id                   => bin.farm_id,
          :farm_code                 => bin.farm_code,
          :farm_rmt_bin_count        => bin.bin_count,
          :farm_rmt_bin_mass         => bin.bin_mass,
          :pro_rata_factor           => pro_rata_factor,
          :track_slms_indicator_code =>bin.track_slms_indicator_code ,
          :maf_lot_number            => ps_lot_number
      )
      pool_graded_ps_farms <<  pool_graded_ps_farm
      end
    end
    return   pool_graded_ps_farms
  end







end