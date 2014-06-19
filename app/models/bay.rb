class Bay < ActiveRecord::Base

  belongs_to :skip 


  def Bay.get_pallet_in_bay(pallet_num)
     query = "SELECT
                public.pallets.pallet_number,  public.skips.skip_code, public.bays.bay_code,
                public.skips.ip_address
                FROM
                public.bay_cartons
                INNER JOIN public.bays ON (public.bay_cartons.bay_id = public.bays.id)
                INNER JOIN public.skips ON (public.bays.skip_id = public.skips.id)
                INNER JOIN public.pallets ON (public.bay_cartons.pallet_id = public.pallets.id)
                 WHERE
                pallets.pallet_number = '#{pallet_num}'
                LIMIT 1"

      return Bay.connection.select_all(query)[0]
    
  end
end
