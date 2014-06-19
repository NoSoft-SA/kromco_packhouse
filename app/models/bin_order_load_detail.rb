class BinOrderLoadDetail < ActiveRecord::Base
  belongs_to :bin_order_load
  belongs_to :bin

  def bin_count?
 bin_count =Bin.find_by_sql("select count(bins.bin_number)as bin_count from bins
                              inner join bin_order_load_details on bin_order_load_details.id=bins.bin_order_load_detail_id
                              where bins.bin_order_load_detail_id = #{self.id}")[0]['bin_count'].to_i
  end

end