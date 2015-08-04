class Tools::ChangeLogsController < ApplicationController
  # To change this template use File | Settings | File Templates.
  def program_name?
	  "change_logs"
  end

  def find_change_logs
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search change logs'"
    dm_session[:redirect] = true
    build_remote_search_engine_form("change_logs.yml", "submit_change_logs_search")
    dm_session[:dm_instance] = false

#    @content_header_caption = "'TOETS'"
#    render :inline=>%{<%= build_find_change_logs_form("execute","execute")%>},:layout=>'content'
  end

  def submit_change_logs_search
    @change_logs = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if(@change_logs.length > 0)
      render :inline => %{
        <% grid            = build_change_logs_grid(@change_logs,false,false)%>
        <% grid.caption    = 'list change logs' %>
        <% @header_content = grid.build_grid_data %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
        },:layout => 'content'
    else
      render :inline => %{
                             <script>
                               alert('no records found');
                             </script>
                           }, :layout => 'content'
    end
  end

  def toets
    @change_log = ChangeLog.new
    @change_log.record_rails_id = params[:parameter_field_action_context]
    @change_log.transaction_business_name = params[:parameter_field_transaction_business_name]
#    @change_log.record_rails_id = params[:change_log_record_rails_id]
#    @change_log.transaction_business_name = params[:change_log_xaction_buz_name]
    render :inline=>%{<%= toets(@change_log,nil,"")%>},:layout=>'content'
  end

  def lookup_rails_record
    record_type = params[:parameter_field_record_type]
    if(record_type)
      settings = {:lookup=>true,
                      :lookup_search_file=>"change_logs/change_log_" + record_type.downcase,#:default_values=>{'commodity_code'=>'AP'},
                      :select_column_name=>'id',
                      :field_name=>'parameter_field_record_rails_id',
                      :submit_to=>params[:submit_to]
                }

      url = ApplicationHelper::TextField.build_look_up_url_configs(self,settings)[:url]
      redirect_to(url)
    else
      render :inline => %{
                             <script>
                               alert('Please select a record type');
                               window.close();
                             </script>
                           }, :layout => 'content'
    end    
  end

  def lookup_doc_name
      document_type = params[:parameter_field_doc_type]
      if(document_type)

        default_values = {}
        params.reject{|key,value| (!key.include?("parameter_field_"))}.map{|key,value|
          default_values.store(key.gsub('parameter_field_','').to_s,value.to_s)
        }

#        dm_session["change_logs/change_log_edi_pi_default_values"] = {'doc_type'=>'POPO'}
        
        settings = {:lookup=>true,
                      :lookup_search_file=>"change_logs/change_log_edi_" + document_type.downcase,
                      :select_column_name=>'doc_name',
                      :field_name=>'parameter_field_doc_name',:default_values=>default_values
                }

        url = ApplicationHelper::TextField.build_look_up_url_configs(self,settings)[:url]
        redirect_to(url)
      else
        render :inline => %{
                               <script>
                                 alert('Please select a document type');
                                 window.close();
                               </script>
                             }, :layout => 'content'
      end
    end

  def build_rails_record_hash_builder
    record_type = params[:parameter_field_record_type]
    @update_field = params[:looked_up_field]
    if(record_type)
      active_record_class = Inflector.camelize(record_type)
      @active_record_instance = eval("#{active_record_class}.new")
      
      @object_builder = ObjectBuilder.new
      @object_attributes = @active_record_instance.attributes
      @object_attributes.store("update_field",@update_field)
      @object_attributes.store("id",nil)
      @hash_object = @object_builder.build_hash_object(@object_attributes) if(@active_record_instance)


      render :inline => %{
        <% @content_header_caption = "'create new pallet'"%>
        <%= build_record_form(@hash_object,'submit_build_record_hash','build record',@object_attributes)%>

        }, :layout => 'content'
    else
      render :inline => %{
                             <script>
                               alert('Please select a record type');
                               window.close();
                             </script>
                           }, :layout => 'content'
    end
  end

  def submit_build_record_hash
    @update_field_id = params[:hash_object][:update_field]
    @record_hash = "%"
    params[:hash_object].sort.each do |key, value|
      if(key != "update_field")
        str_val = value.to_s
        if(str_val.strip == "")
          @record_hash += "%% "
        else
          @record_hash += ":" + key + "=> " + "\\\"" + str_val + "\\\", "
        end
      end
    end

    @record_hash.slice!(@record_hash.length()-2)
    @record_hash += "%"
    
    render :inline => %{
                       <script>
                        var update_field = window.opener.frames[1].document.getElementById("<%=@update_field_id%>");
                        update_field.value = "<%=@record_hash%>";
                        window.close();
                       </script>
                       }, :layout => 'content'
  end

  def view_change_log_record_before
    @field = "record_before"
    view_change_log
  end

  def view_change_log_record_after
    @field = "record_after"
    view_change_log
  end

  def view_change_log_new_record
    @field = "new_record"
    view_change_log
  end

  def view_change_log_deleted_record
    @field = "deleted_record"
    view_change_log
  end

  def view_change_log
    change_log = ChangeLog.find(params[:id])
    hash_string = change_log.attributes[@field]
    hash_string=nil if hash_string == ""
    @hash_object=nil
    if (hash_string)
      @change_log_attributes = eval(hash_string) if(hash_string)
      #@change_log_attributes = hash_string
      @object_builder = ObjectBuilder.new
      @hash_object = @object_builder.build_hash_object(@change_log_attributes)  if   @change_log_attributes
      render :inline => %{
            <% @content_header_caption = "'view change log'"%>            
            <%= build_view_change_log_form(@hash_object,@change_log_attributes) %>
        }, :layout => 'content'
    else
      render :inline => %{
                       <script>
                        alert('record does not exist');
                        window.close();
                       </script>
                       }, :layout => 'content'
    end    
  end

  def compare_change_logs
    change_log = ChangeLog.find(params[:id])
    before_ary = [eval(change_log.record_before)] #if(change_log.record_before)
    after_ary = [eval(change_log.record_after)] #if(change_log.record_after)
    before_ary.delete(nil)
    after_ary.delete(nil)

    before=[]
    after=[]
    if  !before_ary.empty? &&  !after_ary.empty?
      before_ary.each do |rec|
       before << rec.stringify_keys
      end

     if !after_ary.empty?
       after_ary.each do |rec|
        after << rec.stringify_keys
       end
      end
    end
    #before = change_log.record_before if change_log.record_before
    #after = change_log.record_after if change_log.record_after

    parent_header = change_log.transaction_reference
    return_url ="/diagnostics/comparer/hello"
    view_only=true
    left_rec_header  = "#{change_log.record_type} Before"
    right_rec_header = "#{change_log.record_type} After"

    prepare_comparison(before,after,parent_header,nil,left_rec_header,right_rec_header,true,return_url,nil,nil,nil,nil)
  end

end
