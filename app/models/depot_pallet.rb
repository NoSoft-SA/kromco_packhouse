class DepotPallet < ActiveRecord::Base

  belongs_to :intake_header
  has_many :pallet_sequences,:dependent => :delete_all
  has_many :mapped_pallet_sequences,:dependent => :delete_all



  def self.calc_packdate_from_pick_ref (pick_ref,year)

    iso_week = (pick_ref.slice(3,1) + pick_ref.slice(0,1)).to_i
    wday = pick_ref.slice(1,1).to_i
    wday = wday == 7? 0: wday
    firstDayOfYear = "#{year}-01-01".to_datetime()
    iso_week_date = (iso_week -1).weeks.since(firstDayOfYear)
    week_begin_date = iso_week_date.at_beginning_of_week
    fin_date =  (wday - 1).days.since(week_begin_date)

      return fin_date
  end



 def  DepotPallet.remove_pallets(selected_pallets)
  ActiveRecord::Base.transaction do
   for pallet in selected_pallets
     pallet.destroy
   end
    end
 end

  def set_pallet_format_product
     query = "SELECT
                public.cartons_per_pallets.pallet_format_product_code
                FROM
                public.mapped_pallet_sequences
                INNER JOIN public.depot_pallets ON(public.mapped_pallet_sequences.depot_pallet_id = public.depot_pallets.id)
                INNER JOIN public.pallet_bases ON(public.depot_pallets.pallet_base_code =public.pallet_bases.edi_in_pallet_base)
                INNER JOIN public.fg_products ON (public.mapped_pallet_sequences.fg_product_code= public.fg_products.fg_product_code)
                INNER JOIN public.cartons_per_pallets ON(public.fg_products.carton_pack_product_code =public.cartons_per_pallets.carton_pack_product_code)
                AND (public.cartons_per_pallets.cartons_per_pallet =public.depot_pallets.carton_quantity)
                INNER JOIN public.pallet_format_products ON(public.pallet_bases.pallet_base_code =public.pallet_format_products.pallet_base_code)
                AND (public.cartons_per_pallets.pallet_format_product_code= public.pallet_format_products.pallet_format_product_code)
                WHERE
               public.depot_pallets.id = #{self.id} AND
               public.pallet_format_products.market_code = 'X'"


      pfp = self.connection.select_one(query)
      if pfp['pallet_format_product_code']
        self.pallet_format_product_code =  pfp['pallet_format_product_code']
        self.update_attribute(:pallet_format_product_code,pfp['pallet_format_product_code'])
      end
  end

  

end
