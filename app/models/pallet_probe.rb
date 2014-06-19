class PalletProbe < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :job
	belongs_to :probe
	belongs_to :pallet
 
    has_many :pallet_probe_temps, :dependent => :destroy

    def log_to_history
      hist = PalletProbeHistory.new
      self.export_attributes(hist,true)
      hist.create

      temps_copy_query = "insert into pallet_probe_temps_histories (pallet_probes_history_id,fruit_temp,room_temp,measure_unit,battery_status,created_at)
                      select #{hist.id.to_s}, pallet_probe_temps.fruit_temp,pallet_probe_temps.room_temp,
                     pallet_probe_temps.measure_unit,pallet_probe_temps.battery_status,pallet_probe_temps.created_at from
                     pallet_probe_temps where pallet_probe_temps.pallet_probe_id = #{self.id}"

      self.connection.execute(temps_copy_query)

    end

   


end
