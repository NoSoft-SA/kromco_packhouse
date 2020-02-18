class BinPutawayPlanningRule < PDTTransactionState

   def initialize(get_bin_fruit_spec,parent)
     #(stock_type_code, commodity_code, variety_code, size_code, product_class_code, treatment_code, track_indicator1_id, farm_code,bin, scanned_bins )
  #   @stock_type = stock_type_code
  #   @commodity_code = commodity_code
  #   @variety_code = variety_code
  #   @size_code = size_code
  #   @product_class_code = product_class_code
  #   @treatment_code = treatment_code
  #   @track_indicator1_id = track_indicator1_id
  #   @farm_code = farm_code
  #   @num_scanned_bins = scanned_bins
  #   @bin = bin
  #   @grade_code = grade_code
     @get_bin_fruit_spec = get_bin_fruit_spec
     @parent = parent
   end

  def call
    bin_fruit_spec = determine_bin_fruit_spec if @get_bin_fruit_spec
    @parent.bin_fruit_spec = bin_fruit_spec

    self.parent.clear_active_state
    next_state = BinPutawayScanning.new(@parent)
    @parent.set_active_state(next_state)
    return next_state.receive_call_back
  end

  def determine_bin_fruit_spec
    bin_fruit_spec = {}

    if @parent.stock_type_code == "BIN"
      bin_fruit_spec = {
          'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
          'variety_code' => @parent.variety_code, 'size_code' => @parent.size_code, 'product_class_code' => @parent.product_class_code,
          'treatment_code' => @parent.treatment_code,'track_indicator1_id'=> @parent.track_indicator1_id
      }
    elsif @parent.stock_type_code == "REBIN"
      bin_fruit_spec = {
          'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
          'variety_code' => @parent.variety_code, 'product_class_code' => @parent.product_class_code
      }
    end

    if @parent.stock_type_code == "PRESORT"
      if !%w(1A 2L 1L SA).include?("'#{@parent.product_class_code}'") && (!@parent.size_code[0].chr.is_numeric? && !%w(ALL 2L).include?("'#{@parent.size_code}'"))
        bin_fruit_spec = {
            'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
            'variety_code' => @parent.variety_code, 'product_class_code' => @parent.product_class_code
        }


      elsif @parent.size_code=="UNDERS"
        bin_fruit_spec = {
            'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
            'variety_code' => @parent.variety_code, 'product_class_code' => @parent.product_class_code
        }


      elsif  (@parent.size_code[0].chr.is_numeric? && @parent.size_code.include?("-"))
        bin_fruit_spec = {
            'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
            'variety_code' => @parent.variety_code, 'size_code' => @parent.size_code, 'product_class_code' => @parent.product_class_code,
            'treatment_code' => @parent.treatment_code, 'farm_code' => @parent.farm,'track_indicator1_id'=> @parent.track_indicator1_id
        }


      elsif  @parent.size_code == "ALL" && @parent.grade_code == "2L"
        bin_fruit_spec = {
            'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
            'variety_code' => @parent.variety_code, 'size_code' => @parent.size_code, 'product_class_code' => @parent.product_class_code,
            'treatment_code' => @parent.treatment_code, 'farm_code' => @parent.farm,'track_indicator1_id'=> @parent.track_indicator1_id
        }

      else

        bin_fruit_spec = {
            'stock_type_code' => @parent.stock_type_code, 'commodity_code' => @parent.commodity_code,
            'variety_code' => @parent.variety_code, 'size_code' => @parent.size_code, 'product_class_code' => @parent.product_class_code,
            'treatment_code' => @parent.treatment_code,'track_indicator1_id'=> @parent.track_indicator1_id
        }
      end
    end



    return bin_fruit_spec

  end






end