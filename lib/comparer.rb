class Comparer
  require "yaml"

#------------compare tool-------------------------------------------
  #to compare any 2 given dbi/dba datasets
  #call the method prepare_comparison which accepts 2 lists
  #the tool will covert the lists passed to a structure it uses to compare
  #compare tool displays the differences which will be merged
  #to get the merged result call the method get_comparison_result
  #--------get_comparison_result-------------------------------------
  #this method returns the merged data
  #the keys in merged result are the parent_header number and child header name

  #to manipulate the data in merged result there is data stored in session state below =>
# -----    parent_object=session['comparison']['parent_object']
# -----    child_object=session['comparison']['child_object']
# -----    child_table=child_object.tableize.tableize
# -----    parent_table=parent_object.tableize
# -----    original_lists =session['comparison']['compare_lists']
# -----    left_list=session['comparison']['compare_lists'][0]
# -----    right_list=session['comparison']['compare_lists'][0]
  #---convert the recordset to the format that compare tool understands


  def self.calc_discrepancies(left_recordset, right_recordset, parent_key, child_key)
    @session                                    ={}
    compare_lists_keys                          =[parent_key, child_key]

    @session['comparison']                      ={}
    @session['comparison']['compare_lists_keys']=compare_lists_keys
#      @session['comparison']['view_only']=true
#      @session['comparison']['record_headers']=[left_header,right_header]
    left_list                                   =check_children(left_recordset)
    right_list                                  =check_children(right_recordset)
    compare_lists                               =[left_list, right_list]
    @session['comparison']['compare_lists']     =compare_lists
    compiled_diffs                              = compile_differences
    if compiled_diffs == nil
      return nil
    end
    return {'left_diffs'=>compiled_diffs[0],'right_diffs'=>compiled_diffs[1]}
  end

  def self.store_discrepancies(left_diffs, right_diffs, transaction_type, left_parent_id, right_parent_id,edi_doc_type)

    discrep                 =Discrepancy.new
    discrep.transaction_type=transaction_type
    discrep.left_parent_id  =left_parent_id
    discrep.right_parent_id =right_parent_id
    discrep.left_diffs      =left_diffs
    discrep.right_diffs     =right_diffs
    discrep.edi_doc_type     =edi_doc_type
    discrep.save
    discrep
  end

  def self.get_discrepancies(transaction_type, left_parent_id, right_parent_id)
    discrep                    =Discrepancy.find_by_transaction_type_and_left_parent_id_and_right_parent_id(transaction_type, left_parent_id, right_parent_id)
    left_diffs                 =discrep.left_diffs
    right_diffs                =discrep.right_diffs
    discrep_list               =[left_diffs, right_diffs]
    return discrep_list
  end

  def self.check_children(recordset)
    dataset=Array.new
    for record in recordset
      if record.kind_of?(Array)
        if record[0].attributes['children']!=nil
          parent_identifier = record[0][@session['comparison']['compare_lists_keys'][0]]
          kids=records_to_compare_struct(record[0].attributes['children'], "child",parent_identifier)
          rec = record[0].attributes
          rec.delete('children')
          rec['children']     =kids
          record[0].attributes=rec
          record
        end
      elsif record.kind_of?(Hash)
        if record['children']!=nil
          parent_identifier = record[@session['comparison']['compare_lists_keys'][0]]
          kids=records_to_compare_struct(record['children'], "child",parent_identifier)
          record.delete('children')
          record['children']=kids
        end
      else
        if record.attributes['children']!=nil
          parent_identifier = record.attributes[@session['comparison']['compare_lists_keys'][0]]
          kids=records_to_compare_struct(record.attributes['children'], "child",parent_identifier)
          rec = record.attributes
          rec.delete('children')
          rec['children']  =kids
          record.attributes=rec
        end
      end
      dataset << record
    end
    records_to_compare_struct(dataset, "parent",nil)
  end

  def self.records_to_compare_struct(recordset, object,parent_identifier=nil)
    rec_list=Hash.new
    if object=="child"
      if recordset.kind_of?(Array)
        for rec in recordset
          seq_num=parent_identifier.to_s + "_"+ rec[@session['comparison']['compare_lists_keys'][1]].to_s
          if rec.kind_of?(Array)
            rec_list[seq_num]=rec[0].attributes
          elsif rec.kind_of?(Hash)
            rec_list[seq_num]=rec
          else
            rec_list[seq_num]=rec.attributes
          end
        end
        return rec_list
      elsif recordset.kind_of?(Hash)
         seq_num=parent_identifier.to_s + "_"+ @session['comparison']['compare_lists_keys'][1].to_s
        rec_list[seq_num]=recordset
        return rec_list
      else
        seq_num=parent_identifier.to_s + "_"+ recordset[@session['comparison']['compare_lists_keys'][1]].to_s
        record                                                            = Hash.new
        record[recordset[@session['comparison']['compare_lists_keys'][1]]]=recordset.attributes
        return record
      end
    elsif object=="parent"
      if recordset.kind_of?(Array)
        for rec in recordset
          if rec.kind_of?(Array)
            rec_list[rec[@session['comparison']['compare_lists_keys'][0]]]=rec[0].attributes
          elsif rec.kind_of?(Hash)
            rec_list[rec[@session['comparison']['compare_lists_keys'][0]]]=rec
          else
            rec_list[rec[@session['comparison']['compare_lists_keys'][0]]]=rec.attributes
          end
        end
        return rec_list
      elsif recordset.kind_of?(Hash)
        rec_list[@session['comparison']['compare_lists_keys'][0]]=recordset
        return rec_list
      else
        record                                                 = Hash.new
        record[@session['comparison']['compare_lists_keys'][0]]=recordset.attributes
        return record
      end
    end
  end

  def self.prepare_comparison(left_dataset, right_dataset, parent_header, child_header, left_dataset_header, right_dataset_header, view_only, return_url, parent_object, child_object, action_links, mode=nil)
   if left_dataset==nil && right_dataset==nil
      return "LISTS ARE EMPTY NOTHING TO COMPARE "
    end
    if left_dataset==nil
    else
       if left_dataset.kind_of?(Array)

      left_dataset=left_dataset
      else
      left_dataset=[left_dataset]
    end
    end
    if right_dataset==nil
    else
      if right_dataset.kind_of?(Array)
      right_dataset=right_dataset
      else
      right_dataset=[right_dataset]
    end
    end



    compare_lists          =Array.new
    compare_list_keys      =Array.new
    original_list          =Hash.new

    record_headers         =Hash.new
    record_headers['left'] =left_dataset_header
    record_headers['right']=right_dataset_header

    compare_list_keys << parent_header
    compare_list_keys << child_header

    @session                                    ={}
    @session['comparison']                      ={}
    @session['comparison']['mode']              =mode
    @session['comparison']['compare_lists_keys']=compare_list_keys
    @session['comparison']['record_headers']    =record_headers
    @session['comparison']['parent_object']     =parent_object
    @session['comparison']['child_object']      =child_object
    @session['comparison']['original_lists']    =original_list
    @session['comparison']['action_links']      =action_links
    if view_only ==nil
      @session['comparison']['view_only']=false
    else
      @session['comparison']['view_only']=true
    end
    @session['comparison']['return_url']=return_url

    if left_dataset==nil && right_dataset!=nil
      list1=[]
      list2                               =check_children(right_dataset)
      compare_lists << list2
      @session['comparison']['compare_lists']=compare_lists
      @session[:child1_diffs]= nil
      @session[:child2_diffs]=nil
      @session[:left_dataset] =nil
      @session[:right_dataset]=nil
      discrep_list=[list1,list2,@session]
      return discrep_list

    elsif left_dataset!=nil && right_dataset==nil
      list1                               =check_children(left_dataset)
      list2=[]
      compare_lists << list1
      @session['comparison']['compare_lists']=compare_lists
      @session[:child1_diffs]= nil
      @session[:child2_diffs]=nil
      @session[:left_dataset] =nil
      @session[:right_dataset]=nil
      discrep_list=[list1,list2,@session]
      return discrep_list
    else

    list1                               =check_children(left_dataset)

    list2                               =check_children(right_dataset)
      list1_ary                           =Array.new

    compare_lists << list1
    compare_lists << list2
#      session['comparison']={'compare_lists'=>compare_lists}
    @session['comparison']['compare_lists']=compare_lists
    compile_differences
    end



  end

  def self.compile_differences
    left_list        = @session['comparison']['compare_lists'][0]
    right_list       = @session['comparison']['compare_lists'][1]
    left_identifier  =@session['comparison']['compare_lists_keys'][0]
    right_identifier =@session['comparison']['compare_lists_keys'][0]

    left_diffs       =Hash.new
    right_diffs      =Hash.new


    right_list.each {
        |key, value|

      if !left_list.has_key?(key)
#                 left_diffs["'#{key}'"]= nil
        right_diffs[key] =value
      end
    }

    left_list.each {
        |key, value|
      left_child_diffs =Hash.new
      right_child_diffs=Hash.new
      if right_list.has_key?(key)
        diffs      =Array.new
        lft_diffs  = Hash.new
        rght_diffs = Hash.new
        for element in value.keys
      if  element=="qc_result_status"
        elsif  element.include?("status")
        elsif  element=="id"
        elsif  element==@session['comparison']['compare_lists_keys'][0]
        elsif  element==@session['comparison']['compare_lists_keys'][1]
        elsif  element=="status"              || element=="intake_header_id"           || element=="location_code"
        elsif  element =="created_on"         || element=="shipped"                    || element=="load_instruction_detail_id"
        elsif  element=="edi_doc_name"        || element=="load_instruction_mate_id"   || element=="load_instruction_container_id"
        elsif  element=="edi_doc_type"        || element=="allocated"                  || element=="edi_container_number"
        elsif element=="current_error_status" || element=="edi_container_id"           || element=="error_status"
        elsif element=="edited"               || element=="container_id"
        elsif  element=="sequence_edited"     || element=="stock_transfer_id"          || element==""
        elsif  element=="qc_status_code"      || element==""                           || element=="qc_failed_tm"   || element=="mates_header_id"
        elsif  element=="qc_forced_result_id"        || element=="validated"       || element=="load_instruction_vehicle_id"
         elsif   element=="exit_ref"       ||  element=="exit_ref_date_time" || element=="packhouse_code" || element=="rw_action"
        elsif element =="children"
            if (left_list[key][element]!= nil && right_list[key][element]==nil)
              lft_diffs[element]                                        =left_list[key][element]
              lft_diffs[@session['comparison']['compare_lists_keys'][0]]=value[@session['comparison']['compare_lists_keys'][0]]
              diffs << element
            elsif left_list[key][element]== nil && right_list[key][element]!=nil
              rght_diffs[element]                                        =right_list[key][element]
              rght_diffs[@session['comparison']['compare_lists_keys'][0]]=value[@session['comparison']['compare_lists_keys'][0]]
              diffs << element
            elsif left_list[key][element]!= nil && right_list[key][element]!=nil
              result = compare_children(left_list[key][element], right_list[key][element])
              if result != nil
                right_child_diffs[element]=result['child2_diffs']
                left_child_diffs[element] =result['child1_diffs']
                if left_diffs.has_key?(key.to_s)
                  left_diffs[key]['children']=left_child_diffs['children']
                else
                  left_child_diffs[@session['comparison']['compare_lists_keys'][0]]=value[@session['comparison']['compare_lists_keys'][0]]
                  left_diffs[key]                                                  =left_child_diffs
                end
                if right_diffs.has_key?(key.to_s)
                    right_diffs[key]['children']=right_child_diffs
                else
                    right_child_diffs[@session['comparison']['compare_lists_keys'][0]]=value[@session['comparison']['compare_lists_keys'][0]]
                    right_diffs[key]                                                  =right_child_diffs
                  end
              end
            end
        else
            if right_list[key].has_key?(element)
            if value[element].to_s.strip != right_list[key][element].to_s.strip

              diffs << element
              if right_diffs.has_key?(key.to_s)
                rght_diffs[element]=right_list[key][element]
              else
                rght_diffs[element]                                        =right_list[key][element]
                rght_diffs[@session['comparison']['compare_lists_keys'][0]]=value[@session['comparison']['compare_lists_keys'][0]]
              end
              if left_diffs.has_key?(key.to_s)
                lft_diffs[element]=value[element]
              else
                lft_diffs[element]                                        =left_list[key][element]
                lft_diffs[@session['comparison']['compare_lists_keys'][0]]=value[@session['comparison']['compare_lists_keys'][0]]
              end
            end
          end
          end
#          end
        end
    
        if right_list[key].keys.include?("children")&& !value.keys.include?("children")
          kids            =Hash.new
          kids["children"]=right_list[key]["children"]
          right_diffs[key]=kids
        end
        if !diffs.empty?
          if right_diffs.has_key?(key.to_s)
            for ele in rght_diffs
              if ele[0]!=@session['comparison']['compare_lists_keys'][1]
                right_diffs[key][ele[0]]=ele[1]
              end
            end
            else
            right_diffs[key]=rght_diffs
          end
          if left_diffs.has_key?(key.to_s)
            for ele in lft_diffs
              if ele[0]!=@session['comparison']['compare_lists_keys'][1]
                left_diffs[key][ele[0]]=ele[1]
              end
            end
           else
            left_diffs[key]=lft_diffs
           end
        end

      else
        left_diffs[key]=value

      end
#
    }


    child1_diffs=Hash.new
    child2_diffs=Hash.new
  if !left_diffs.empty?
    for dif in left_diffs
      if dif[1].has_key?("children")
        for child in dif[1]['children']
           child1_diffs[child[0]]=child[1]
        end
      end
    end
  end
  if !right_diffs.empty?
    for diff in right_diffs
     if diff[1].has_key?("children")
       for child in diff[1]['children']
           child2_diffs[child[0]]=child[1]
       end
     end
    end
  end
    @session[:child1_diffs]= child1_diffs
    @session[:child2_diffs]=child2_diffs
    @session[:left_dataset] =left_diffs
    @session[:right_dataset]=right_diffs
    diff_list               =([left_diffs, right_diffs, @session])
    if left_diffs=={} && right_diffs=={}
      return nil
    else
      return diff_list
    end

  end

  def self.compare_children(child1, child2)

    child1_diffs = Hash.new
    child2_diffs =Hash.new
    child1_real_diffs =Hash.new
    child2_real_diffs =Hash.new
    child2.each {
        |key, value|
      if !child1.has_key?(key)
#                     child1_diffs[""]= nil
        child2_diffs[key] =value
        child2_real_diffs[key]=value
      end
    }
    child1.each {
        |key, value|
      if child2.has_key?(key)
        diffs      =Array.new
        left_diffs =Hash.new
        right_diffs=Hash.new
        for element in value.keys
          if  element.include?("created_on")
            elsif element=="created_on"
            elsif element=="id"
            elsif element=="status"
            elsif element=="pallet_number"
            elsif element=="created_on"
            elsif element=="qc_status_code"
            elsif element=="qc_result_status"
            elsif  element=="inspector_number"
            elsif  element=="batch_code"
            elsif  element=="inspection_date"
            elsif  element=="temperature" || element=="rw_action"
            elsif  element=="temperature1" || element=="original_packed_tm_group"
            elsif  element=="temperature2" || element=="original_packed_tm_group_code"
            elsif  element=="temperature3" || element=="inspection_report"
            elsif  element=="temperature4" || element=="shipped_tm_group"|| element=="shipping_tm_group" || element=="fin_tm_group" || element=="product_characteristics" || element=="remarks" || element=="seq_ctn_qty"
            elsif  element=="packhouse_code" ||  element=="exit_ref" || element=="seq_ctn_qty"|| element=="exit_ref_date_time" || element=="inspection_report"

            else
              if  child2[key].has_key?(element)
                if value[element].to_s.strip != child2[key][element].to_s.strip
                  diffs << element
                  left_diffs[element]=value[element]
                  if left_diffs.has_key?(@session['comparison']['compare_lists_keys'][1])
                  else
                    left_diffs[@session['comparison']['compare_lists_keys'][1]]=value[@session['comparison']['compare_lists_keys'][1]]
                  end
                  if right_diffs.has_key?(@session['comparison']['compare_lists_keys'][1])
                  else
                    right_diffs[@session['comparison']['compare_lists_keys'][1]]=child2[key][@session['comparison']['compare_lists_keys'][1]]
                  end

                  right_diffs[element]=child2[key][element]
                end
              end
            end

          end


        if !diffs.empty?
#                      child1_diffs["#{key}"]=value
#                      child2_diffs["#{key}"]=child2[key]
          child1_diffs[key]=left_diffs
          child2_diffs[key]=right_diffs

        end
      else
        child1_diffs[key]=value
#                      child2_diffs["'#{key}'"]= nil

      end
    }
    difs                   =Hash.new
    difs["child1_diffs"]   =child1_diffs
    difs["child2_diffs"]   =child2_diffs
    if child1_diffs.empty? &&  child2_diffs.empty?
      return nil
    elsif child1_diffs=={} &&  !child2_diffs.empty?
      return difs
    elsif !child1_diffs.empty? &&  child2_diffs=={}
      return difs
    elsif !child1_diffs.empty? &&  !child2_diffs.empty?
      return difs
    end

  end

  def self.check_selected(data)
    data_ary   =Array.new
    left_data  =Array.new
    right_data = Array.new
    data.each {
        |key, value|
      if (value == "1" && key =~ /\bdata/)
        key_split=key.split("!")
        key_split.pop
        key_join=key_split.join("!")
        data_ary << key_join
      end
    }
    keys   = Hash.new
    key_ary=Array.new
    data_ary.each do |n|
      if keys.has_key?(n)
        key_ary << n.split("!")[1]
      else
        keys.store(n, n)
      end

    end
    if key_ary.length > 0
      return key_ary
    else
      return nil
    end

  end

  def self.merge(data,comparison)
    session={}
    session['comparison']=comparison
    @session={}
    @session['comparison']=comparison
    @session['comparison'][:result]                 =comparison['comparison']['compare_lists'][0]
    @session['comparison'][:result]['parent_object']=comparison['comparison']['parent_object']
    @session['comparison'][:result]['child_object'] =comparison['comparison']['child_object']

    column                                          =Hash.new
    data.each do |key, value|
      key_ary =key.split("!")
      if key =~ /\bstructure/
        if value == "1"
          if key =~/\bnew/
            if key =~/\bparent/
              record_id = key.split("!")[0]
              record    =@session['comparison'][:right_dataset][record_id]
              #if record.has_key?("children")
              #  record.delete("children")
              #end
              recordd ={record_id=>record}
              if @session['comparison'][:result].has_key?("insert")
                @session['comparison'][:result]['insert'][record_id.to_i]=record
              else
                rec                                      ={record_id=>record}
                @session['comparison'][:result]['insert']= rec
              end
            end

            if key =~/\bchild/
              key_split            = key.split("child")
              parent_id            = key_split[1].split("!")[0]
              child_id             = key_split[0].split("!")[0]
              parent_record        = @session['comparison'][:right_dataset][parent_id]
              selected_child       = parent_record['children']
              selected_child_record=selected_child[child_id]
              if @session['comparison'][:result].has_key?("insert")
                @session['comparison'][:result]['insert'][child_id]=selected_child_record
              else
                record                                   =Hash.new
                rec                                      = child_id
                record[rec]                              =selected_child_record
                @session['comparison'][:result]['insert']=record
              end
            end
          end
        end
        if value == "0"
          if key =~/\bnew/
          else
            if key=~/\bparent/
              key_split = key.split("!")
              record_id =key_split[0]
              record    =@session['comparison'][:left_dataset][record_id]
              if @session['comparison'][:result].has_key?('delete')
                @session['comparison'][:result]['delete'][record_id.to_i]=record
              else
                rec                                      ={record_id=>record}
                @session['comparison'][:result]['delete']= rec
              end

            end
            if key =~/\bchild/
              field     =Hash.new
              key_split = key.split("child")
              parent_id = key_split[1].split("!")[0]
              parent    =@session['comparison'][:left_dataset][parent_id]
              child_id  = key_split[0].split("!")[0]
              child     =parent['children'][child_id]
              recorrd   =Hash.new
              if @session['comparison'][:result].has_key?("delete")
                @session['comparison'][:result]['delete'][child_id]=child
              else
                rec                                      = child_id
                recorrd[rec]                             =child
                @session['comparison'][:result]['delete']=recorrd

              end

            end
          end
        end
      end
      if key =~ /\bdata/
        if value=="1"
          if key =~/\bparent/
            if key_ary.last =="right"
              key_split           = key.split("!")
              record_id           =key_split[0]
              record              = @session['comparison'][:right_dataset][record_id]
              left_record         = @session['comparison'][:result][record_id]
              column[key_split[1]]=record[key_split[1]]
              if @session['comparison'][:result].has_key?('update')
                if @session['comparison'][:result]['update'].has_key?(record_id)
                  @session['comparison'][:result]['update']["#{record_id}"][key_split[1]]=record[key_split[1]]
                else
                  @session['comparison'][:result]['update']["#{record_id}"]=column
                end

              else
                hash                                     =Hash.new
                hash[record_id]                          =column
                @session['comparison'][:result]['update']=hash
              end
            end
          end
          if key =~/\bchild/
            if key_ary.last =="right"
              field            =Hash.new
              key_split        = key.split("child")
              key_split_split  = key_split[1].split("!")
              parent_id        =key_split[1].split("!")[0]
              parent_record    = @session['comparison'][:right_dataset][parent_id]
              child_id         = key_split[0].split("!")[0]
              field[key_ary[1]]=parent_record['children'][child_id][key_ary[1]]
              if @session['comparison'][:result].has_key?("update")

                if @session['comparison'][:result]['update'].has_key?(child_id)
                  @session['comparison'][:result]['update'][child_id][key_ary[1]]=parent_record['children'][child_id][key_ary[1]]
                else
                  @session['comparison'][:result]['update'][child_id]=field

                end

              else
                record                                   =Hash.new
                rec                                      = child_id
                record[rec]                              =field
                @session['comparison'][:result]['update']=record
              end
            end
          end
        end
      end
    end
return  @session['comparison'][:result]
  end


  def self.get_comparison_result
    return @session['comparison'][:result]
  end


end

