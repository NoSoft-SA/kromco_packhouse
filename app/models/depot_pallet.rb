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

    #---------------------------------------------------------------------------------------------------------------------------------------
    # Try to handle scenario where, in the early part of year(Jan typically), cartons were packed during last month (or 2) of previous year
    # In such a case the current calender year, and the season, of the carton would be correct, but the pack-date would be one year in future
    #----------------------------------------------------------------------------------------------------------------------------------------
    if fin_date > Time.now()
      fin_date - 1.year
    else
      return fin_date
    end

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
