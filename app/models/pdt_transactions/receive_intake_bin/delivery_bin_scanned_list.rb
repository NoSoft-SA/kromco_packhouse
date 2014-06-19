class DeliveryBinScannedList
    attr_accessor :delivery_id,:mode

  def initialize(delivery_id,mode)
   @delivery_id = delivery_id
   @mode = mode
  end


  def push(bin_number)
     ActiveRecord::Base.transaction do
      delivery_bin_scan=DeliveryBinScan.new
      delivery_bin_scan.bin_number= bin_number.to_s
      delivery_bin_scan.delivery_id = self.delivery_id.to_i
      delivery_bin_scan.mode= self.mode
      delivery_bin_scan.save
      end
  end

  def length
    count=DeliveryBinScan.find_by_sql("select count(distinct bin_number) as count from delivery_bin_scans where delivery_id=#{delivery_id.to_i} and mode='#{mode.to_s}'").map{|d|d.count}[0].to_i
    return count.to_i
  end

  def include?(bin_number)
    bin_num=DeliveryBinScan.find_by_sql("select bin_number from delivery_bin_scans where bin_number='#{bin_number}'and mode='#{mode.to_s}' ")
          return true if !bin_num.empty?
  end

  def each
     begin
       bin_numbers = DeliveryBinScan.find_by_sql("select distinct bin_number from delivery_bin_scans where delivery_id=#{delivery_id.to_i} and mode='#{mode.to_s}'").map{|b|b.bin_number}
       for bin_num in bin_numbers
         yield bin_num
       end
     rescue
       raise $!
     end
  end

  def check(bin_number)

    bin_num= Bin.find_by_sql("select bin_number from bins where bin_number='#{bin_number}'")
    if ! bin_num.empty?
       bin_num =  bin_num[0]['bin_number']
       return  bin_num
    else
      return nil
    end


  end

end