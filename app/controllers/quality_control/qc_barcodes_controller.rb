class QualityControl::QcBarcodesController < ApplicationController

    def program_name?
      "qc_barcodes"
    end

    def bypass_generic_security?
      true
    end

    def new_qc_barcode
      return if authorise_for_web(program_name?,'create') == false
      render_new_qc_barcode
    end

    def render_new_qc_barcode
      render :inline => %{
        <% @content_header_caption = "'create new qc_barcode'"%>

        <%= build_qc_barcode_form(@qc_barcode,'create_qc_barcode','create qc barcode',false,@is_create_retry)%>

      }, :layout => 'content'
    end

    def create_qc_barcode
      begin
        @qc_barcode = QcBarcode.new(params[:qc_barcode])
         if @qc_barcode.save
           redirect_to_index("'new record created successfully'","'create successful'")
         else
          @is_create_retry = true
          render_new_qc_barcode
         end
      rescue
         handle_error("qc barcode record could not be created")
      end
    end

    def list_qc_barcodes
      return if authorise_for_web(program_name?,'read') == false

      if params[:page]!= nil

        session[:qc_barcodes_page] = params['page']

         render_list_qc_barcodes

         return
      else
        session[:qc_barcodes_page] = nil
      end

      list_query = "@qc_barcodes_pages = Paginator.new self, QcBarcode.count, @@page_size,@current_page
       @qc_barcodes = QcBarcode.find(:all,
             :limit => @qc_barcodes_pages.items_per_page,
             :offset => @qc_barcodes_pages.current.offset)"
      session[:query] = list_query
      render_list_qc_barcodes
    end

    def render_list_qc_barcodes
      @can_edit = authorise(program_name?,'edit',session[:user_id])
      @can_delete = authorise(program_name?,'delete',session[:user_id])
      @current_page = session[:qc_barcodes_page] if session[:qc_barcodes_page]
      @current_page = params['page'] if params['page']
      @qc_barcodes =  eval(session[:query]) if !@qc_barcodes
      
      render :inline => %{
      <% grid            = build_qc_barcodes_grid(@qc_barcodes,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all qc barcodes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@qc_barcodes_pages) if @qc_barcodes_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    end

    def edit_qc_barcode
     return if authorise_for_web(program_name?,'edit')==false
     id = params['id']
     if id && @qc_barcode = QcBarcode.find(id)
       puts "PASS_FAIL_BOOLEAN :: " + @qc_barcode.pass_fail_boolean.to_s
       render_edit_qc_barcode
     else

     end
  end

  def render_edit_qc_barcode
     render :inline => %{
		<% @content_header_caption = "'edit qc barcode'"%>

		<%= build_qc_barcode_form(@qc_barcode,'update_qc_barcode','update qc barcode',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_qc_barcode
      begin
    	if params[:page]
    		session[:qc_barcodes_page] = params['page']
    		render_list_qc_barcodes
    		return
    	end

    		@current_page = session[:qc_barcodes_page]
    	 id = params[:qc_barcode][:id]
    	 if id && @qc_barcode = QcBarcode.find(id)
    		 if @qc_barcode.update_attributes(params[:qc_barcode])
    			@qc_barcode = eval(session[:query])
    			flash[:notice] = 'qc_barcode record updated!'
    			render_list_qc_barcodes
         else
           render_edit_qc_barcode
         end
    	 end
      rescue
         handle_error("qc_barcode could not be updated")
       end
  end

  def delete_qc_barcode
     begin
    	return if authorise_for_web(program_name?,'delete')== false
    	if params[:page]
    		session[:qc_barcodes_page] = params['page']
    		render_list_qc_barcodes
    		return
    	end
    	id = params[:id]
    	if id && qc_barcode = QcBarcode.find(id)
    		qc_barcode.destroy
    		session[:alert] = " Record deleted."
    		render_list_qc_barcodes
    	end
      rescue
         handle_error("qc_barcode record could not be deleted")
      end
  end

end
