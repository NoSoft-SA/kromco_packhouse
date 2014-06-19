# CSM edi in flow (Cold Storage temperatures).
class Csm

  # Scan the xml for MesData node to get the date and time.
  # Scan for all Data nodes to get the temperatures and create PalletProbeTemp records.
  # If the EDI file has been delayed after the probe has changed pallet,
  # create PalletProbeTempsHistory records instead.
  def execute( xml )
    node_set = xml.xpath('.//MesData')
    raise EdiInError, "MesData node not found" if node_set.empty?

    node = node_set.first
    d,m,y = node['Date'].split('-')
    h,n,s = node['Time'].split('-')
    time_stamp = Time.local(y,m,d,h,n,s)

    data_nodes = node_set.xpath('.//Data')
    raise EdiInError, "Data nodes not found" if data_nodes.empty?
    data_nodes.each do |data_node|
      # First check the pallet probe history:
      # If there is a record there for this probe that was created after the timestamp of
      # this temperature measurement, the probe was changed before the EDI temperature arrived.
      # Therefore we need to update the history, not the active probe.
      pallet_probe_hist = PalletProbeHistory.find(:first,
                             :conditions => ['probe_code = ? AND created_at > ?',
                                            data_node['TransponderID'], time_stamp],
                             :order => 'created_at DESC')
#      pallet_probe_hist = nil

      if pallet_probe_hist.nil?
        probe = Probe.find(:first,
                           :conditions => ['probe_code = ?',
                                          data_node['TransponderID']])
        raise EdiInError, "Probe with probe code '#{data_node['TransponderID']}'" <<
        " and active when temperature measured at #{time_stamp.strftime('%Y-%m-%d %H:%M')} does not exist" if probe.nil?
        pallet_probe = PalletProbe.find_by_probe_id_and_pallet_id(probe.id, probe.current_pallet_reference_id)
        raise EdiInError, "PalletProbe with probe id '#{probe.id}'" <<
        " and pallet_id '#{probe.current_pallet_reference_id}' not found." if pallet_probe.nil?
        PalletProbeTemp.create( :pallet_probe_id => pallet_probe.id,
                                :fruit_temp => data_node['Probe'].to_f,
                                :room_temp => data_node['Ambient'].to_f,
                                :measure_unit => data_node['MeasureUnit'],
                                :battery_status => data_node['BatteryStatus'],
                                :created_at => time_stamp)
      else
        PalletProbeTempHistory.create( :pallet_probe_history_id => pallet_probe_hist.id,
                                :fruit_temp => data_node['Probe'].to_f,
                                :room_temp => data_node['Ambient'].to_f,
                                :measure_unit => data_node['MeasureUnit'],
                                :battery_status => data_node['BatteryStatus'],
                                :created_at => time_stamp)
      end
    end
  end

end
