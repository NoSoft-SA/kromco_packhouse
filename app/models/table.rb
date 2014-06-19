class Table < ActiveRecord::Base

  has_many :carton_pack_stations,:dependent => :destroy
  
  belongs_to :drop
  
  
  def Table.number_across_drops?
   true
  end
  
  def Table.exists_for_line_config(line_config_id,table_caption)
  
   query = "SELECT tables.id
          FROM
          public.tables
          INNER JOIN public.drops ON (public.tables.drop_id = public.drops.id)
          INNER JOIN public.line_configs ON (public.drops.line_config_id = public.line_configs.id)
          WHERE
         (line_configs.id = '#{line_config_id}' and table_caption = '#{table_caption}')"
           
     return Drop.find_by_sql(query)[0]
   
  end
  
  def Table.next_global_id(line_config_id)
  
   query = "SELECT max(tables.table_caption)as maxval
          FROM
          public.tables
          INNER JOIN public.drops ON (public.tables.drop_id = public.drops.id)
          INNER JOIN public.line_configs ON (public.drops.line_config_id = public.line_configs.id)
          WHERE
         (line_configs.id = '#{line_config_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
   
  end
  
  def Table.next_id(drop_id)
  
   query = "SELECT max(tables.table_code)as maxval
           FROM
           public.tables where 
           (tables.drop_id = '#{drop_id}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
   
  end
  
  
end
