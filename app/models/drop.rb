class Drop < ActiveRecord::Base
 
 belongs_to :line_config
 has_many :tables,:dependent => :destroy 
 has_many :binfill_stations,:dependent => :destroy
 
 validates_presence_of :drop_code
 validates_presence_of :drop_side_code

 def Drop.next_id(line_config_id)
  
   query = "SELECT max(drops.drop_code)as maxval
           FROM
           public.drops where 
           (drops.line_config_id = '#{line_config_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
   
  end
  
    def Drop.exists_for_line_config(config_id,drop_code)
  
   query = "SELECT drops.drop_code
           FROM
           public.drops
           INNER JOIN public.line_configs ON (public.drops.line_config_id = public.line_configs.id)
           WHERE
           (public.line_configs.id = '#{config_id}') AND 
           (public.drops.drop_code = '#{drop_code}')"
  
   return Drop.find_by_sql(query)[0]
  
  end


end
