class BinPutawayPlanningRule < ActiveRecord::Base

  # def initialize
  #   (stock_type_code= nil , commodity_code= nil , variety_code= nil , size_code= nil , product_class_code= nil , treatment_code= nil , track_indicator1_id= nil , farm_code= nil , grade_code= nil , scanned_bins=nil )
  #   @stock_type_code = stock_type_code
  #   @commodity_code = commodity_code
  #   @variety_code = variety_code
  #   @size_code = size_code
  #   @product_class_code = product_class_code
  #   @treatment_code = treatment_code
  #   @track_indicator1_id = track_indicator1_id
  #   @farm_code = farm_code
  #   @num_scanned_bins = scanned_bins
  #   @grade_code = grade_code
  # end

  # def call
  #   bin_fruit_spec = determine_bin_fruit_spec if @get_bin_fruit_spec
  #   return bin_fruit_spec
  #   # @parent.bin_fruit_spec = bin_fruit_spec
  #   #
  #   # self.parent.clear_active_state
  #   # next_state = BinPutawayScanning.new(@parent)
  #   # @parent.set_active_state(next_state)
  #   # return next_state.receive_call_back
  # end

  def BinPutawayPlanningRule.determine_bin_fruit_spec(stock_type_code= nil , commodity_code= nil , variety_code= nil , size_code= nil , product_class_code= nil , treatment_code= nil , track_indicator1_id= nil , farm_code= nil , grade_code= nil , scanned_bins=nil )

  bin_fruit_spec = {}

  if stock_type_code == "BIN"
    bin_fruit_spec = {
        'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
        'variety_code' => variety_code, 'size_code' => size_code, 'product_class_code' => product_class_code,
        'treatment_code' => treatment_code,'track_indicator1_id'=> track_indicator1_id
    }
  elsif stock_type_code == "REBIN"
    bin_fruit_spec = {
        'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
        'variety_code' => variety_code, 'product_class_code' => product_class_code
    }
  end

  if stock_type_code == "PRESORT"
    if !%w(1A 2L 1L SA).include?("'#{product_class_code}'") && (!size_code[0].chr.is_numeric? && !%w(ALL 2L).include?("'#{size_code}'"))
      bin_fruit_spec = {
          'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
          'variety_code' => variety_code, 'product_class_code' => product_class_code
      }


    elsif size_code=="UNDERS"
      bin_fruit_spec = {
          'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
          'variety_code' => variety_code, 'product_class_code' => product_class_code
      }


    elsif  (size_code[0].chr.is_numeric? && size_code.include?("-"))
      bin_fruit_spec = {
          'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
          'variety_code' => variety_code, 'size_code' => size_code, 'product_class_code' => product_class_code,
          'treatment_code' => treatment_code, 'farm_code' => farm,'track_indicator1_id'=> track_indicator1_id
      }


    elsif  size_code == "ALL" && grade_code == "2L"
      bin_fruit_spec = {
          'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
          'variety_code' => variety_code, 'size_code' => size_code, 'product_class_code' => product_class_code,
          'treatment_code' => treatment_code, 'farm_code' => farm,'track_indicator1_id'=> track_indicator1_id
      }

    else

      bin_fruit_spec = {
          'stock_type_code' => stock_type_code, 'commodity_code' => commodity_code,
          'variety_code' => variety_code, 'size_code' => size_code, 'product_class_code' => product_class_code,
          'treatment_code' => treatment_code,'track_indicator1_id'=> track_indicator1_id
      }
    end
  end


    return bin_fruit_spec

  end







end