class ProcessGradingRuleFile
  require "csv"
  attr_reader :user_name


  def initialize(file_name,user,object_type,season_id)
    @user_name = user
    @file_name = file_name
    @object_type = object_type
    @season_id = season_id
    # @presort_staging_runs = PresortStagingRun.find_by_sql("
    #   select t.track_slms_indicator_code,s.season_code
    #   from presort_staging_runs p
    #   inner join seasons s on p.season_id=s.id
    #   inner join track_slms_indicators t on p.track_slms_indicator_id=t.id
    #   where presort_unit='#{params['staging']['presort_unit']}'
    # ")
  end

  def call
    if @object_type == "cartons"
      csv_file_headers_order, csv_file_lines, csv_file_name_first_part, difference, required_cols_order,receivers,pods,pod_receivers,pod_and_receivers,pod_receiver_hash,customers = process_carton_grading_csv_file
    elsif @object_type == "rebins"
      csv_file_headers_order, csv_file_lines, csv_file_name_first_part, difference, required_cols_order,receivers,pods,pod_receivers,pod_and_receivers,pod_receiver_hash,customers = process_csv_file
    end

    if !difference.empty?
      return "File must contain columns in the following order:<br> #{required_cols_order.join(',')}"
    end

    validate_file(csv_file_lines)


    #store file under 'public/uploads/rmt_processing/grower_grading/grading_rules' appending date and time to file name
    file_name = "#{Globals.get_grading_rule_folder}/#{csv_file_name_first_part[0].to_s}_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}.csv"

    store_csv_file(file_name,csv_file_lines.join(','))

    apply_grading_rules(csv_file_headers_order, csv_file_lines, file_name, required_cols_order)

    #create_pod_receivers(csv_file_headers_order, csv_file_lines, file_name, required_cols_order,receivers,pods,pod_receivers,pod_and_receivers,pod_receiver_hash,customers)

  end

  def apply_grading_rules(csv_file_headers_order, csv_file_lines, file_name, required_cols_order)
    create_carton_grading_rules(csv_file_lines,required_cols_order)
  end

  def create_carton_grading_rules(csv_file_lines,required_cols_order)
    num_of_cols = required_cols_order.length
    ActiveRecord::Base.transaction do
    csv_file_lines.each do |line|
      carton_grading_rule_header = CartonGradingRuleHeader.new(
          # :created_at => Time.now,
          # :created_by => @user_name,
          # :updated_by => Time.now,
          :deactivated => false,
          :activated => true,
          :deactivated_at => Time.now,
          :activated_at => Time.now,
          :season_id => @season_id
      )
      carton_grading_rule_header.save
      ctn_grading_rule_col_values = []
      for i in 0..num_of_cols-1
        ctn_grading_rule_col_values << "'#{line[i]}'"
      end
      carton_grading_rules = ActiveRecord::Base.connection.execute("
      INSERT INTO carton_grading_rules(carton_grading_rule_header_id,deactivated_at,activated_at,activated,deactivated,
                                       #{required_cols_order.join(',')})
                                VALUES(#{carton_grading_rule_header.id},'#{Time.now}','#{Time.now}',true,false,
                                       #{ctn_grading_rule_col_values.join(',')})
                                 RETURNING carton_grading_rules.*;")
      carton_grading_rules

    end
  end


  end


  def validate_file(csv_file_lines)
    comparison_array = []
    duplicate_array = []
    uniq_array = []
    new_sizes = []
    new_classes  = []
    errors = []
    csv_file_lines.each do |line|
      comparison_array << [line[0],line[1],line[2],line[3],line[4],line[5]]
      uniq_array << "#{line[0]},#{line[1]},#{line[2]},#{line[3]},#{line[4]},#{line[5]}" if !uniq_array.include?("#{line[0]},#{line[1]},#{line[2]},#{line[3]},#{line[4]},#{line[5]}")
      new_sizes << "'#{line[6]}'"
      new_classes << "'#{line[7]}'"
    end
    if uniq_array.length < csv_file_lines.length
      errors <<  "File contains duplicate records:<br>"
    end

   sizes   = ActiveRecord::Base.connection.select_all("select size_code from sizes where size_code in (#{new_sizes.join(',')})").map{|x|x['size_code']}
   classes = ActiveRecord::Base.connection.select_all("select product_class_code from product_classes where product_class_code in (#{new_classes.join(',')})").map{|x|x['product_class_code']}
    invalid_classes = []
    invalid_sizes = []

    if sizes.length < new_sizes.length
      new_sizes.each do |size| invalid_sizes << size if !new_sizes.include?("'#{size}'") end
    elsif classes.length < new_classes.length
      new_classes.each do |clas| invalid_classes << clas if !new_classes.include?("'#{clas}'") end
    end

    errors << "Invalid size/s:(#{invalid_sizes.join(',')}) AND invalid classes:(#{invalid_classes.join(',')}):<br>" if !invalid_classes.empty? && !invalid_sizes.empty?
    errors << "Invalid size/s:(#{invalid_sizes.join(',')})" if !invalid_sizes.empty?
    errors << "Invalid classes:(#{invalid_classes.join(',')}):<br>" if !invalid_classes.empty?

    return "<br> #{errors.join('<BR>')}" if !errors.empty?

  end

  def process_carton_grading_csv_file
    @csv_file_configs = YAML.load(File.read("#{Globals.get_grading_csv_file_configs_folder}/carton_grading_rule_file_configs.yml"))


    csv_file,  csv_file_name_first_part, required_cols_order = get_csv_file_configs()


    csv_file_headers_order, csv_file_lines, qry= get_csv_file_headers_order(csv_file)


    #verify if column order is correct
    difference = verify_file_columns_order(required_cols_order, csv_file_headers_order, true)
    return csv_file_headers_order, csv_file_lines, csv_file_name_first_part, difference, required_cols_order, qry
  end

  def get_csv_file_configs()
    csv_file = @file_name
    csv_file_name = File.basename(csv_file.original_filename)
    csv_file_name_first_part = csv_file_name.to_s.split('.', 2)


    required_cols_order = @csv_file_configs['grading_criteria']['required_columns'].split(',')
    primary_look_up_field = @csv_file_configs['grading_criteria']['primary_look_up_field'].split(',')
    @primary_look_up_field_index = get_primary_look_up_field_index(required_cols_order, primary_look_up_field)
    @total_required_columns = @csv_file_configs['grading_criteria']['total_required_columns']
    return csv_file,  csv_file_name_first_part, required_cols_order
  end

  def get_csv_file_headers_order(csv_file)
    csv_file_lines = []
    pallet_numbers = []
    required_cols = @csv_file_configs['grading_criteria']['total_required_columns']
    qry = []
    if csv_file.respond_to? :tempfile
      CSV.foreach(csv_file.tempfile) do |line|
        csv_file_lines << line #.inspect
        qry << "pgc.actual_size_count_code ='#{line[0]}' AND pgc.product_class_code = '#{line[1]}' AND pgc.variety_short_long = '#{line[2]}'
         AND pgc.grade_code = '#{line[3]}' AND pgc.line_type = '#{line[4]}' AND pgf.track_slms_indicator_code = '#{line[5]}' "
      end
    else
      CSV.parse(csv_file.read).each do |line|
        csv_file_lines << line #.inspect
         qry << "pgc.actual_size_count_code ='#{line[0]}' AND pgc.product_class_code = '#{line[1]}' AND pgc.variety_short_long = '#{line[2]}'
         AND pgc.grade_code = '#{line[3]}' AND pgc.line_type = '#{line[4]}' AND pgf.track_slms_indicator_code = '#{line[5]}' "
      end
    end

    #remove 4 header lines
    csv_header_lines = @csv_file_configs['grading_criteria']['csv_header_lines']
    csv_header_lines.times do
      csv_file_lines.shift
    end


    #get file headers and remove file headers from csv_file_lines
    csv_file_headers_order = csv_file_lines.shift
    return csv_file_headers_order, csv_file_lines,qry
  end

  def get_primary_look_up_field_index(required_cols_order,primary_look_up_field)
    index = required_cols_order.index(primary_look_up_field.to_s.downcase)
    return index
  end

  def verify_file_columns_order(required_cols_order,csv_file_headers_order,flexi_order=nil)
    cnt = 0
    count = 0
    correct_required_col_order = []
    required_cols_hsh = {}
    csv_file_headers_hsh = {}
    required_cols_order.each do |col|
      required_cols_hsh[col]=cnt
      cnt= cnt +1
    end
    csv_file_headers_order.each do |col|
      csv_file_headers_hsh[col]=count
      count= count +1
    end
    difference =[]
    csv_file_headers_order.each { |element|
      if required_cols_hsh[element.strip] != csv_file_headers_hsh[element]
        difference << element
      else
        correct_required_col_order << element
      end
    }

    difference = []  if flexi_order && (correct_required_col_order.length == required_cols_order.length)

    return difference
  end

  def store_csv_file(full_path,lines)
    begin
      create_file(full_path)
      file = File.new(full_path,"w")
      lines.each do |line|
        file.puts line + "\n"
      end
      file.close
    rescue
      raise "File: " + full_path + " could not be created. Exception reported is: \n" + $!
    end
  end

  def create_file(full_path)
    if not File.exists?(full_path)
      File.new(full_path, "w").close()
    end
  end

end