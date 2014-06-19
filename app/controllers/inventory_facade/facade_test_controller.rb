# To change this template, choose Tools | Templates
# and open the template in the editor.

class InventoryFacade::FacadeTestController < ApplicationController
  def program_name?
    "facade_test"
  end

  #@scope_tester = nil
  #@mrl_print_msg = ""

  def bypass_generic_security?
    true
  end

  def find_pdt_program
    render :inline => %{
		<% @content_header_caption = "'find pdt program'"%>
		<%= build_find_pdt_program_form(@program,'submit_find_pdt_program','search')%>
		}, :layout => 'content'
  end

  def submit_find_pdt_program
    where = nil
    where = " display_name='#{params[:program][:display_name]}' " if(params[:program][:display_name].to_s.strip.length > 0)
    where += " and " if(where && (params[:program][:class_name].to_s.strip.length > 0))
    where = where.to_s + " class_name='#{params[:program][:class_name]}' " if(params[:program][:class_name].to_s.strip.length > 0)
    @programs = Program.find_by_sql("
                      select programs.program_name,programs.display_name,programs.class_name
                      from programs
                      where (#{where})
                      UNION
                      select program_functions.name as program_name,program_functions.display_name,program_functions.class_name
                      from program_functions
                      where (#{where})")

    render :inline => %{
      <% grid            = build_pdt_program_grid(@programs)%>
      <% grid.caption    = 'List pdt programs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@account_type_pages) if @account_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    },:layout => 'content'
  end


  def create_stock
    render :inline => %{
		<% @content_header_caption = "'create stock'"%>

		<%= build_create_stock_from(@stock,'create_stock_submit','createk')%>

		}, :layout => 'content'

#    render :inline => %{
#		<div style="overflow: hidden;border: gray solid thin;width: 1250px; height: 750px;">
#        <applet code="sample_bin_weighing_app/za.co.multitier.sample_bin_weighing.SampleBinWeighingUI" archive="sample_bin_weighing_app/SampleBinWeighingApp.jar,sample_bin_weighing_app/lib/log4j-1.2.14.jar" style="width: 100%; height: 100%;"  />
#    </div>
#
#		}, :layout => 'content'
  end

  def create_stock_submit
    ActiveRecord::Base.transaction do
      Inventory.create_stock(params[:stock][:owner_party_role_id], params[:stock][:stock_tpe], params[:stock][:farm_code], params[:stock][:truck_code], params[:stock][:trans_name], params[:stock][:trans_id], params[:stock][:location], params[:stock][:stock_ids].split(','))
      render :inline => %{}
    end
  end

  def move_stock
    render :inline => %{
		<% @content_header_caption = "'move stock'"%>

		<%= build_move_stock_from(@stock,'move_stock_submit','move')%>

		}, :layout => 'content'
  end

  def move_stock_submit
    ActiveRecord::Base.transaction do
      Inventory.move_stock(params[:stock][:trans_name],params[:stock][:trans_id],params[:stock][:location_to], params[:stock][:stock_ids].split(','))
      render :inline => %{}
    end
  end

  def undo_move_stock
    render :inline => %{
		<% @content_header_caption = "'undo_move_stock'"%>

		<%= build_undo_stock_from(@stock,'undo_move_stock_submit','undo_move')%>

		}, :layout => 'content'
  end

  def undo_move_stock_submit
    ActiveRecord::Base.transaction do
      Inventory.undo_move_stock(params[:stock][:stock_ids].split(','),params[:stock][:transaction_business_name],params[:stock][:reference_number])
      render :inline => %{}
    end    
  end

  def remove_stock
    render :inline => %{
		<% @content_header_caption = "'remove stock'"%>

		<%= build_remove_stock_from(@stock,'remove_stock_stock_submit','remove')%>

		}, :layout => 'content'
  end

  def remove_stock_stock_submit
    ActiveRecord::Base.transaction do
      Inventory.remove_stock(params[:stock][:truck_code], params[:stock][:stock_type], params[:stock][:trans_name], params[:stock][:trans_id], params[:stock][:location], params[:stock][:stock_ids].split(','))
#    Inventory.remove_stock(params[:stock][:truck_code], params[:stock][:stock_type], params[:stock][:trans_name], params[:stock][:trans_id], params[:stock][:location], params[:stock][:stock_ids].split(','),""+params[:stock][:location])
      render :inline => %{}
    end    
  end

  def undo_remove_stock
    render :inline => %{
		<% @content_header_caption = "'remove stock'"%>

		<%= build_undo_remove_stock_from(@stock,'undo_remove_stock_submit','undo_remove')%>

		}, :layout => 'content'
  end

  def undo_remove_stock_submit
    ActiveRecord::Base.transaction do
      Inventory.undo_destroy_stock(params[:stock][:stock_ids].split(','),params[:stock][:trans_name],params[:stock][:reference_number])
      render :inline => %{}
    end    
  end
end
