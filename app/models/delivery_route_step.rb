class DeliveryRouteStep < ActiveRecord::Base
    belongs_to :route_step
    belongs_to :delivery

  def self.bulk_update(set_map, condition_attr, pallet_nums=nil, additional_criteria=nil)
    updates = ""
    for key in set_map.keys
      updates += key.to_s + "=" + set_map[key].to_s + ","
    end
    updates.chop!

    conditions = ""
    if (pallet_nums != nil)
      for pallet_num in pallet_nums
        conditions += condition_attr + "=" + pallet_num.to_s + " or "
      end
    end

    if (additional_criteria != nil)
      for ikey in additional_criteria.keys
        conditions += ikey.to_s + "=" + additional_criteria[ikey].to_s + " or "
      end
    end

    conditions.chop!.chop!.chop! if conditions.length > 3
    puts "e-BULK iUPDATE STMT = set(" + updates +")\n " + "where (" + conditions + ")"
    DeliveryRouteStep.update_all(ActiveRecord::Base.extend_set_sql_with_request(updates,"delivery_route_steps"), conditions)

  end
end