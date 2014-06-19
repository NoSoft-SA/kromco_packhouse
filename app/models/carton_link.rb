class CartonLink < ActiveRecord::Base

  belongs_to :production_run
  belongs_to :carton_setup
  belongs_to :carton_label_setup
  belongs_to :carton_template
  belongs_to :active_device
  belongs_to :pallet_template
  belongs_to :pallet_label_setup
  
  belongs_to :rebin_label_setup
  belongs_to :rebin_template
  belongs_to :rebin_setup
  

  
  
  
  def CartonLink.links_for_side_and_run(side_code,run_id)
  
    query = "SELECT 
            public.carton_links.drop_code
            FROM
            public.carton_links
            INNER JOIN public.pack_group_outlets ON (public.carton_links.production_run_id = public.pack_group_outlets.production_run_id)
            WHERE
            (public.carton_links.production_run_id = '#{run_id}') AND 
            ((public.pack_group_outlets.outlet1 = public.carton_links.drop_code) OR 
            (public.pack_group_outlets.outlet2 = public.carton_links.drop_code) OR 
            (public.pack_group_outlets.outlet3 = public.carton_links.drop_code) OR 
            (public.pack_group_outlets.outlet4 = public.carton_links.drop_code) OR
            (public.pack_group_outlets.outlet5 = public.carton_links.drop_code) OR 
            (public.pack_group_outlets.outlet6 = public.carton_links.drop_code) OR
            (public.pack_group_outlets.outlet7 = public.carton_links.drop_code) OR
            (public.pack_group_outlets.outlet8 = public.carton_links.drop_code) OR
            (public.pack_group_outlets.outlet9 = public.carton_links.drop_code) OR
            (public.pack_group_outlets.outlet10 = public.carton_links.drop_code) OR     
            (public.pack_group_outlets.outlet11 = public.carton_links.drop_code) OR 
            (public.pack_group_outlets.outlet12 = public.carton_links.drop_code)AND
            public.carton_links.drop_side_code = '#{side_code}')"
     
     return CartonLink.find_by_sql(query)       
  
  
  end


end
