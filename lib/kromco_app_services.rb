module Kromco


  module EdiServices
    def display_mail_logs
      if(@email_logs.length > 0)
          render :inline => %{
        <% grid            = build_intake_email_logs_trail_grid(@email_logs) %>
        <% grid.caption    = 'list email logs trail for intake header' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@email_logs_pages) if @email_logs_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
      else
        render :inline => %{
                             <script>
                               alert('no records found');
                               window.close();
                             </script>
                           }, :layout => 'content'
      end
    end

    def view_intake_email_log
      @email_log = EmailLog.find(params[:id])
      @attachment_content_html = @email_log.attachment_content.gsub("<![CDATA[","").gsub("]]>","")
      render :inline => %{<%= @attachment_content_html %>}
    end

    def execute_create_missing_master_files
      submission = eval(params['selection']['list'])
      mfs_to_create = session[:current_missing_mfs].select {|f| (submission.include?(f["id"].to_i)) }

      begin
#      notices = []
#      mfs_to_create.each do |mf_to_create|
#        #---------------
#        lookup_params_sequence = "'#{mf_to_create['mf_value']}'"
#        lookup_clause = "find_by_#{mf_to_create['mf_name']}"
#        if(mf_to_create['extra_look_up_fields'])
#          mf_to_create['extra_look_up_fields'].map{|key,val|
#            lookup_clause += "_and_" + key
#            lookup_params_sequence += ",'#{val}'"
#          }
#        end
#        #---------------
#        if(!(@master_file = eval("#{Inflector.camelize(Inflector.singularize(mf_to_create['mf_type']))}.#{lookup_clause}(#{lookup_params_sequence})")))
#          @master_file = eval("#{Inflector.camelize(Inflector.singularize(mf_to_create['mf_type']))}.new({:#{mf_to_create['mf_name']}=>'#{mf_to_create['mf_value']}'})")
#          if(mf_to_create['dependent_fields'])
#            mf_to_create['dependent_fields'].each do |parent_mf|
#              @new_parent_mf = Pallet.create_parent_master_file(parent_mf,@master_file)
#            end
#          end
#          #---------------
#          lookup_params_sequence = "'#{mf_to_create['mf_value']}'"
#          lookup_clause = "find_by_#{mf_to_create['mf_name']}"
#          if(mf_to_create['extra_look_up_fields'])
#            mf_to_create['extra_look_up_fields'].map{|key,val|
#              lookup_clause += "_and_" + key
#              lookup_params_sequence += ",'#{@master_file.attributes[key]}'"
#            }
#          end
#          #---------------
#          if(!(eval("#{Inflector.camelize(Inflector.singularize(mf_to_create['mf_type']))}.#{lookup_clause}(#{lookup_params_sequence})")) && @master_file.new_record?)
#            @master_file.save!
#          else
#            @master_file.update
#          end
#        else
#          notices.push("master_file[#{mf_to_create['mf_name']}=#{mf_to_create['mf_value']}] already exists")
#        end
#        mf_to_create.store('created_on',Time.now)
#      end
#      return notices
        return Pallet.create_missing_mfs(mfs_to_create)
      rescue
        raise $!
      end
    end

    def view_mf_records
      @mfs = session[:current_missing_mfs]
      mf_to_view = @mfs.select {|f| (f["id"].to_s == params[:id]) }[0]
      session[:record_ids] = []
      record_ids = mf_to_view['record_ids'].split(',').each do |record_id|
        session[:record_ids].push({'record_type'=>mf_to_view['records_type'],'record_id'=>record_id})
      end

      @records = session[:record_ids]
      if(@records.length > 0)
          render :inline => %{
        <% grid            = build_missing_mf_records_grid(@records) %>
        <% grid.caption    = 'list of records with missing masterfiles' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
      else
        render :inline => %{
                             <script>
                               alert('no records found');
                               window.close();
                             </script>
                           }, :layout => 'content'
      end
    end

    def view_mf_record
      @rec = session[:record_ids].select {|f| (f["record_id"].to_s == params[:id]) }[0]
      if(@rec['record_type'] == 'edi_pallet_sequences')
        id = @rec['record_id'].split("_")
        if(!(@active_record_instance = PalletSequence.find_by_pallet_number_and_pallet_sequence_number(id[0],id[1].to_i)))
          @active_record_instance = EdiPalletSequence.find_by_pallet_number_and_pallet_sequence_number(id[0],id[1].to_i)
        end
        @table_name = 'edi_pallet_sequences'
      elsif(@rec['record_type'] == 'pallets')
        if(!(@active_record_instance = Pallet.find_by_pallet_number(@rec['record_id'])))
          @active_record_instance = EdiPallet.find_by_pallet_number(@rec['record_id'])
        end
        @table_name = 'edi_pallets'
      end

      @content_header_caption = "'record view'"
      render :inline => %{
      <%= build_view_record_form(@active_record_instance, nil, "none", @table_name)%>
      }, :layout => 'content'
    end




  end

  module ComparerServices

        def to_discrep_htm(left_diffs,right_diffs,left_header,right_header,parent_key,child_key,action_links=nil,mode=nil,view=nil)
           if(view==nil)
             #LUKS
             left_diffs = {} if(!left_diffs)
             right_diffs = {} if(!right_diffs)

             @child1_diffs=Hash.new
             for element in left_diffs
               if  element[1].has_key?("children")
                for child in  element[1]['children']
                  @child1_diffs[child[0]]=child[1]
                end
               end
             end
             @child2_diffs=Hash.new
             for element in right_diffs
               if  element[1].has_key?("children")
                for child in  element[1]['children']
                  @child2_diffs[child[0]]=child[1]
                end
               end
             end
             @view = "view_only" if view==nil
             @list1_diffs =left_diffs
             @list2_diffs =right_diffs
             @left_diff_list =left_diffs.sort
             @right_diff_list = right_diffs.sort
             compare_list_keys=[parent_key,child_key]
             @header_list = compare_list_keys
             @content_header_caption = "'View Discrepancies'"
             record_headers={"left"=>left_header,"right"=>right_header}
             @record_headers=record_headers
             @action_links=action_links
             @mode=mode

             @discrepanies_keys = (@list1_diffs.keys + @list2_diffs.keys).uniq

             htm = render_to_string(:file =>'app/views/diagnostics/comparer/view_only_comparer.rhtml')
           else
             #NETSAI
             @child1_diffs=Hash.new
             for element in left_diffs
              if  element[1].has_key?("children")
               for child in  element[1]['children']
                 @child1_diffs[child[0]]=child[1]
               end
              end
             end
             @child2_diffs=Hash.new
             for element in right_diffs
              if  element[1].has_key?("children")
               for child in  element[1]['children']
                 @child2_diffs[child[0]]=child[1]
               end
              end
             end
              @view = "view_only" if view==nil
              @list1_diffs =left_diffs
              @list2_diffs =right_diffs
              @left_diff_list =left_diffs.sort
              @right_diff_list = right_diffs.sort
          #      @session[:left_diff_list]=@left_diff_list
          #      @session[:right_diff_list]=@right_diff_list
          #      @session[:left_dataset]=left_diffs
          #      @session[:right_dataset]=right_diffs
              compare_list_keys=[parent_key,child_key]
              @header_list = compare_list_keys
              @content_header_caption = "'View Discrepancies'"
              record_headers={"left"=>left_header,"right"=>right_header}
              @record_headers=record_headers
              @action_links=action_links
              @mode=mode

              htm = render_to_string(:file =>'app/views/diagnostics/comparer/compare.rhtml')
           end
          end

        def display_diffs(left_diffs,right_diffs,left_header,right_header,parent_key,child_key,action_links=nil,mode=nil,view=nil)
              @child1_diffs=Hash.new
             for element in left_diffs
              if  element[1].has_key?("children")
               for child in  element[1]['children']
                 @child1_diffs[child[0]]=child[1]
               end
              end
             end
             @child2_diffs=Hash.new
             for element in right_diffs
              if  element[1].has_key?("children")
               for child in  element[1]['children']
                 @child2_diffs[child[0]]=child[1]
               end
              end
             end
              @view = "view_only" if view==nil
              @list1_diffs =left_diffs
              @list2_diffs =right_diffs
              @left_diff_list =left_diffs.sort
              @right_diff_list = right_diffs.sort
        #      @session[:left_diff_list]=@left_diff_list
        #      @session[:right_diff_list]=@right_diff_list
        #      @session[:left_dataset]=left_diffs
        #      @session[:right_dataset]=right_diffs
              compare_list_keys=[parent_key,child_key]
              @header_list = compare_list_keys
              @content_header_caption = "'View Discrepancies'"
              record_headers={"left"=>left_header,"right"=>right_header}
              @record_headers=record_headers
              @action_links=action_links
              @mode=mode
              render :file =>'app/views/diagnostics/comparer/compare.rhtml',:layout => "content"

          end

        def display_diffs_internal(disrepancy_list)#internal

              @view = disrepancy_list[2]['comparison']['view_only']
              @list1_diffs =disrepancy_list[0]
              @list2_diffs =disrepancy_list[1]
              @left_diff_list =disrepancy_list[0].sort
              @right_diff_list = disrepancy_list[1].sort
              @child1_diffs =disrepancy_list[2][:child1_diffs]
              @child2_diffs=disrepancy_list[2][:child2_diffs]
              @session[:left_diff_list]=@left_diff_list
              @session[:right_diff_list]=@right_diff_list
              @session[:left_dataset]=disrepancy_list[0]
              @session[:right_dataset]=disrepancy_list[1]
              @header_list = disrepancy_list[2]['comparison']['compare_lists_keys']
              @content_header_caption = "'View  and merge differences'"
              @record_headers=disrepancy_list[2]['comparison']['record_headers']
              @action_links=disrepancy_list[2]['comparison']['action_links']
              @mode=disrepancy_list[2]['comparison']['mode']
              render :file =>'app/views/diagnostics/comparer/compare.rhtml',:layout => "content"
           end

        def go_to_url
             session[:comparer_session]
               render :inline => %{<script>
                                       alert('merged');
                                       window.close()
                                       window.opener.frames[1].location.href = "#{session[:comparer_session]['comparison']['return_url']}"
                                   </script>}
           end

        def merge
             if !session[:params_list]
             data = params[:list]
             else
               data=session[:params_list]
               end
               msg =Comparer.check_selected(data)
               if msg !=nil
                flash[:error] = "SELECT from  one side: <BR> #{msg.join("<BR>")} "
               to_b_compared=[@session[:left_dataset],@session[:right_dataset],@session[:comparer_session]]
                display_diffs_internal(to_b_compared)
                return

               end
              selected = data.values
             if !selected.include?("1")
                flash[:error] = "you did not select anything"
                display_diffs_internal([@session[:left_dataset],@session[:right_dataset],session[:comparer_session]])
                return
             end
             merged_result =Comparer.merge(data,session[:comparer_session])
             session[:merged_result]=merged_result
             redirect_to  :controller => "logistics/reworks",:action =>"update_ok_wit_checkboxes",:merged_result=>session[:merged_result]

             if session[:comparer_session]['comparison']['return_url']
               go_to_url
             end
           end


        def ok_cancel
           if params['commit']=="ok"
             if params[:list]== nil
               redirect_to  :controller => "logistics/reworks",:action =>"update_ok"
             else
             session[:params_list]=params[:list]
              merge

             end

           elsif params['commit']=="cancel"

              redirect_to  :controller => "logistics/reworks",:action =>"update_cancel_edit"
           end
           end

        def prepare_comparison(left_dataset,right_dataset,parent_identifier,child_identifier,left_dataset_header,right_dataset_header,view_only,return_url,parent_object,child_object,action_links,mode)
             discrepancy_list =Comparer.prepare_comparison(left_dataset,right_dataset,parent_identifier,child_identifier,left_dataset_header,right_dataset_header,view_only,return_url,parent_object,child_object,action_links,mode)
             if discrepancy_list==nil
              @list1_diffs =nil
              @list2_diffs =nil
               render :file =>'app/views/diagnostics/comparer/compare.rhtml',:layout => "content"
             elsif discrepancy_list=="LISTS ARE EMPTY NOTHING TO COMPARE "
             render :inline => %{<script>
                                     alert("LISTS ARE EMPTY NOTHING TO COMPARE  ");
                                      window.close();
                                      </script>} and return
             else
              session[:comparer_session]=discrepancy_list[2]
             display_diffs_internal(discrepancy_list)
             end

           end

      end

  module ReworksServices

    def select_pallets_for_reworks(run_params,conditions,view_sql = nil)
         session[:new_rw_run_params]={}
         session[:new_rw_run_params][:business_context] =run_params[:business_context]
         session[:new_rw_run_params][:business_process_id]=run_params[:business_process_id]
         session[:new_rw_run_params][:rw_run_type]=run_params[:rw_run_type]
         session[:new_rw_run_params][:edi_doc_type]=run_params[:edi_doc_type]
         session[:new_rw_run_params][:edi_doc_id]=run_params[:edi_doc_id]

         rw_run =RwRun.find_by_business_context_and_business_process_id_and_status(run_params[:business_context].to_s,run_params[:business_process_id].to_s,"EDITING")
         if rw_run
           return "cannot create a new run ,complete the one in editing mode for this business process"
         end
          view_external_pallets(conditions,view_sql,'logistics/reworks/submit_selected_pallets')
       end

       def view_pallets(conditions, sql = nil,multi_select = nil, discrepancy_id = nil, pallets_table_name = nil, pallet_sequences_table_name = nil, custom_action_links = nil,styling_class_name = nil)
        session[:pallets_view]={}
        session[:pallets_view][:conditions]=conditions
        session[:pallets_view][:view_sql]=sql
        session[:pallets_view][:multi_select]=multi_select
        session[:pallets_view][:discrepancy_id]=discrepancy_id
        session[:pallets_view][:pallets_table_name]=pallets_table_name
        session[:pallets_view][:pallet_sequences_table_name]=pallet_sequences_table_name
        session[:pallets_view][:custom_action_links]=custom_action_links
        session[:pallets_view][:styling_class_name]=styling_class_name

      #  redirect_to("logistics/reworks/rw_view_pallets")
       redirect_to :action => "rw_view_pallets", :controller => "logistics/reworks"
       end

       def view_external_pallets(conditions, sql = nil,multi_select = nil, discrepancy_id = nil, pallets_table_name = nil, pallet_sequences_table_name = nil, custom_action_links = nil,styling_class_name = nil)
        session[:pallets_view]={}
        session[:pallets_view][:conditions]=conditions
        session[:pallets_view][:view_sql]=sql
        session[:pallets_view][:multi_select]=multi_select
        session[:pallets_view][:discrepancy_id]=discrepancy_id
        session[:pallets_view][:pallets_table_name]=pallets_table_name
        session[:pallets_view][:pallet_sequences_table_name]=pallet_sequences_table_name
        session[:pallets_view][:custom_action_links]=custom_action_links
        session[:pallets_view][:styling_class_name]=styling_class_name

      #  redirect_to("logistics/reworks/rw_view_pallets")
       redirect_to :action => "rw_view_external_pallets", :controller => "logistics/reworks"
       end

    def check_status(object)
        ob_class =object.class
        status_type_code=Inflector.tableize(ob_class)
        if ob_class==Order
            status_position =Status.find_by_status_code_and_status_type_code(object.status,status_type_code)
            unedited_position =Status.find_by_status_code_and_status_type_code("ALLOCATING_PALLETS",status_type_code)
            if status_position
              status_position=status_position.position
              if status_position==nil
                status_position=0
              end
            else
              status_position=0
            end
            if unedited_position
              unedited_position=unedited_position.position
              if unedited_position==nil
                unedited_position=0
              end
              else
              unedited_position=0
            end
        end
        if ob_class==Consignment
            status_position =Status.find_by_status_code_and_status_type_code(object.status,status_type_code)
            unedited_position =Status.find_by_status_code_and_status_type_code("ALLOCATING_PALLETS",status_type_code)
            if status_position
              status_position=status_position.position
              if status_position==nil
                status_position=0
              end
            else
              status_position=0
            end
            if unedited_position
              unedited_position=unedited_position.position
              if unedited_position==nil
                unedited_position=0
              end
              else
              unedited_position=0
            end
        end
        if ob_class==LoadInstruction
            status_position =Status.find_by_status_code_and_status_type_code(object.status,status_type_code)
            unedited_position =Status.find_by_status_code_and_status_type_code("MATES_RECEIVED",status_type_code)
             if status_position
              status_position=status_position.position
              if status_position==nil
                status_position=0
              end
            else
              status_position=0
            end
            if unedited_position
              unedited_position=unedited_position.position
              if unedited_position==nil
                unedited_position=0
              end
              else
              unedited_position=0
            end
        end
        return status_position,unedited_position
      end

    def activate_reworks_run(run)
      session[:active_rw_run]=run
       if session[:active_doc]==nil
           session[:active_doc]={}
          end
          session[:active_doc]['rw_run']=run.id
      @info_sticker = "current reworks run is: " + run.rw_run_name
      end
  end







end
