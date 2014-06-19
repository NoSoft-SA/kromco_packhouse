class Diagnostics::ComparerController < ApplicationController


  def program_name?
    "comparer"
  end

  def bypass_generic_security?
    true
  end

  def test_comparer_tool

	render :inline => %{
		<% @content_header_caption = "'test comparer tool'"%>

		<%= build_test_compare_tool_form(@compare,'','',true)%>

		}, :layout => 'content'

  end

  def view
   result=  get_comparison_result
    result
  end


  
  def get_parameters
    left_dataset = list1
    right_dataset = list2
    parent_header_list="depot_pallet_number"
    child_header_list="pallet_sequence_number"
    return_url ="/diagnostics/comparer/test_comparer_tool/"
    view_only=nil
    left_rec_header  = "left"
    right_rec_header = "right"
  prepare_comparison(left_dataset,right_dataset,parent_header_list,child_header_list,left_rec_header,right_rec_header,view_only,return_url)
  end

  def list1

    record1=DepotPallet.find_by_sql("select id,depot_pallet_number,pallet_format_product_code from depot_pallets where id=325 ")[0].attributes

    record2=DepotPallet.find_by_sql("select id,depot_pallet_number,pallet_format_product_code from depot_pallets where id=336 ")[0].attributes

    record2_children=PalletSequence.find_by_sql("select id,pallet_sequence_number ,commodity,variety,grade from pallet_sequences where depot_pallet_id=336 ")

    record2['children']=record2_children

    dataset1 =Array.new

    dataset1 << record1

    dataset1 << record2

    return dataset1

  end



def list2

#    record1=DepotPallet.find_by_sql("select id,depot_pallet_number,pallet_format_product_code from depot_pallets where id=325 ")[0].attributes

    record2=DepotPallet.find_by_sql("select id,depot_pallet_number,pallet_format_product_code from depot_pallets where id=336 ")[0].attributes

    record2_children=PalletSequence.find_by_sql("select id,pallet_sequence_number ,commodity,variety,grade from pallet_sequences where depot_pallet_id=336 ")

#    record1_children=PalletSequence.find_by_sql("select id,pallet_sequence_number ,commodity,variety,grade from pallet_sequences where depot_pallet_id=325 ")



     record2_children[0].commodity = "KL"

     record2['children']=record2_children





    dataset2=Array.new

#    dataset2 << record1

    dataset2 << record2





    return dataset2

  end














































end



