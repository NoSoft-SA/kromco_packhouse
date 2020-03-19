# To change this template, choose Tools | Templates
# and open the template in the editor.
 
class Services::SampleBinWeighingController < ApplicationController
  def program_name?
    "sample_bin_weighing"
  end

  def bypass_generic_security?
    true
  end

  def valid_trip_sheet


    begin
      tripsheet_number = params[:id].to_s
#      puts "tripsheet_number = " + tripsheet_number
      vehicle_job = VehicleJob.find_by_vehicle_job_number(tripsheet_number)
      if(!vehicle_job)
        send_error("tripsheet #{tripsheet_number} not found")
        return
      else
        #delivery_number : non-numeric crashes
        delivery = Delivery.find_by_delivery_number(tripsheet_number)
        if(!delivery)
          send_error("delivery #{tripsheet_number} not found")
          return
        end
        arrived_at_complex_step = DeliveryRouteStep.find_by_delivery_number_and_route_step_code(tripsheet_number,"arrived_at_complex")
        if(!arrived_at_complex_step)
          send_error("route_step[arrived_at_complex] not found")
          return
        elsif(!arrived_at_complex_step.date_completed)
          send_error("route_step[arrived_at_complex] not done")
          return
        end

        sample_bin_weigh_completed_delivery_route_step = DeliveryRouteStep.find_by_delivery_number_and_route_step_code(tripsheet_number,"sample_bin_weigh_completed")
        if(!sample_bin_weigh_completed_delivery_route_step)
          send_error("route_step[sample_bin_weigh_completed] not found")
          return
        elsif(sample_bin_weigh_completed_delivery_route_step.date_completed)
          send_error("sample_bin_weighing already completed for this delivery")
          return
        end

        if Delivery.connection.select_one("select count(*) from delivery_sample_bins where delivery_id = #{delivery.id.to_s}")['count'].to_i == 0
          send_error("no sample bins required")
          return
        else
          bins = Bin.find_by_sql("SELECT bins.bin_number,rmt_products.rmt_product_code,rmt_products.commodity_code,deliveries.delivery_number,bins.created_on,farms.farm_code,
            bins.orchard_code,bins.is_sample_bin,bins.is_half_bin,bins.weight as bin_weight,pack_material_products.material_mass
            from bins
              JOIN deliveries ON bins.delivery_id=deliveries.id
                JOIN farms ON bins.farm_id = farms.id
                  JOIN rmt_products ON rmt_products.id=bins.rmt_product_id
                    JOIN pack_material_products on pack_material_products.id = bins.pack_material_product_id
            where delivery_id='#{delivery.id}' and (is_sample_bin=true or is_half_bin=true) ORDER BY bin_number")
          
          if(bins.length == 0)
            send_error("no bins received for this delivery")
            return
          elsif((bad_bins = bins.select{|g| g.material_mass==nil}).length > 0)
            send_error("bins[#{bad_bins.map{|b| b.bin_number}.join(",")}] do not have a material_mass")
            return
          else
            result_set = package_result_set(bins)
            send_response(result_set)
            return
          end
        end        
      end
    rescue
      send_error($!.to_s)
      return
#      raise $!
    end
  end

  def complete_delivery
    tripsheet_number = params[:id]
    delivery = Delivery.find_by_delivery_number(tripsheet_number)
    input = params[:input]
    begin
      ActiveRecord::Base.transaction do
        ActiveRequest.set_active_request("system", "sample_bin_weighing", "complete_delivery", "SBW")
        sample_bin_weighing = DeliveryRouteStep.find_by_delivery_number_and_route_step_code(tripsheet_number,"sample_bin_weigh_completed")
        sample_bin_weighing.update_attributes!({:date_activated=>Time.now.to_formatted_s(:db),:date_completed=>Time.now.to_formatted_s(:db)})

        rec_set = REXML::Document.new(input).root
        sample_bin_avg_weight = 0
        count = 0
        rec_set.elements.each do |element|
          bin = Bin.find_by_bin_number(element.attributes['bin_number'])
          if(element.attributes['is_half_bin'] == 'true' || element.attributes['commodity_code'] == 'PL')
            material_mass = PackMaterialProduct.find(bin.pack_material_product_id).material_mass.to_f
            bin.update_attributes!({:weight=>(element.attributes['bin_weight'].to_f - material_mass)})
          elsif(element.attributes['is_sample_bin'] == 'true')
            sample_bin_avg_weight += element.attributes['bin_weight'].to_f
            count+=1
          end
        end
        sample_bin_avg_weight = (sample_bin_avg_weight/count).to_f if(count > 0)

        if(delivery.commodity_code != 'PL')
          all_bins = Bin.find_by_sql("select * from bins where bins.delivery_id=#{delivery.id} and bins.is_half_bin is not true")
          non_sample_bins_or_clause = " (bin_number='#{all_bins.map{|b| b.bin_number}.join("' or bin_number='")}') "
          ActiveRecord::Base.connection.execute("update bins
          set weight=(#{sample_bin_avg_weight}-p.material_mass)
          from pack_material_products p
          where (p.id=bins.pack_material_product_id)
          and #{non_sample_bins_or_clause}")
        end
      end
      send_response("<complete>delivery weighing completed OK</complete>")
      return
    rescue
      handle_error_silently("service: sample bin weighing complete failed. Reported exception: " + $!)
      send_error($!.to_s)
      return
    ensure
      ActiveRequest.clear_active_request
    end
  end

  def package_result_set(result_set)
     record_set = "<recordset>"     
      record = ""
       result_set.each do |result|
         record = "<record "
           result.attribute_names.each do |attr_name|
             record += attr_name.to_s + "='" + result.attributes[attr_name].to_s + "' "
           end
         record += "/>"
         record_set += record
       end
     record_set += "</recordset>"

     return record_set
  end
  
  def send_response(result)
    @result = result
    puts "Response/Result = " + result
    render :inline => %{
                       <%= @result %>
                       }
 end

 def send_error(err_msg)

   @error = err_msg
   puts "Error/Result = " + err_msg
   render :inline => %{
                       <error><%= @error %></error>
                       }
 end
end
