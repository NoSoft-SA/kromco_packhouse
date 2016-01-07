class  Qc::QcPluginController < ApplicationController

  # Include the layout here for any rhtml
  layout 'content'

  # Because this controller manages several different programs
  # we need to ask ProgramFunction for the actual program name given the qc_inspection_type_code (url_param).
  def program_name(qc_inspection_type_code)
    ProgramFunction.generic_program_name( 'QC', qc_inspection_type_code )
  end

  def bypass_generic_security?
    true
  end

  # "Plugin" : Reads FTA measurements and populates measurement results for Pressure and Diameter tests.
  def get_qtyfs_fta_test_values
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      delivery_no             = @qc_inspection.inspection_reference # delivery_number_preprinted
      if authorise_for_web(program_name(qc_inspection_type_code),'edit')
        fta_session = InstrumentsFtaSession.find(:first,
                                                :conditions => ['test_type = ? AND transaction_id = ?',
                                                                qc_inspection_type_code, delivery_no],
                                                :order => 'created_on DESC')
        if fta_session.nil?
          flash[:error] = "There are no FTA measurements for \"#{delivery_no}\""
        else
          if msg = fta_session.import_for( @qc_inspection )
            flash[:error] = "Unable to get test values. Error is #{msg}."
          else
            flash[:notice] = 'Tests have been populated with values.'
          end
        end
      else
        flash[:error] = "You do not have permission to perform this action."
      end
    else
      flash[:error] = "Unable to find inspection."
    end

    redirect_to :controller => 'qc/qc_inspection',
                :action     => 'edit_qc_inspection',
                :id         => id

  end

  # "Plugin" : Reads RFM measurements and populates measurement results for Sugar tests.
  def get_qtyfs_rfm_test_values
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      delivery_no             = @qc_inspection.inspection_reference
      if authorise_for_web(program_name(qc_inspection_type_code),'edit')
        rfm_session = InstrumentsRfmSession.find(:first,
                                                :conditions => ['test_type = ? AND transaction_id = ?',
                                                                qc_inspection_type_code, delivery_no],
                                                :order => 'created_on DESC')
        if rfm_session.nil?
          flash[:error] = "There are no RFM measurements for \"#{delivery_no}\""
        else
          if msg = rfm_session.import_for( @qc_inspection )
            flash[:error] = "Unable to get test values. Error is #{msg}."
          else
            flash[:notice] = 'Tests have been populated with values.'
          end
        end
      else
        flash[:error] = "You do not have permission to perform this action."
      end
    else
      flash[:error] = "Unable to find inspection."
    end
    redirect_to :controller      => 'qc/qc_inspection',
                :action          => 'edit_qc_inspection',
                :id              => id

  end
  
    # "Plugin" : Reads FTA measurements and populates measurement results for Pressure and Diameter tests.
  def get_pretip_fta_test_values
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      bin_no             = @qc_inspection.inspection_reference 
      if authorise_for_web(program_name(qc_inspection_type_code),'edit')
        fta_session = InstrumentsFtaSession.find(:first,
                                                :conditions => ['test_type = ? AND transaction_id = ?',
                                                                qc_inspection_type_code, bin_no],
                                                :order => 'created_on DESC')
        if fta_session.nil?
          flash[:error] = "There are no FTA measurements for \"#{bin_no}\""
        else
          if msg = fta_session.import_for( @qc_inspection )
            flash[:error] = "Unable to get test values. Error is #{msg}."
          else
            flash[:notice] = 'Tests have been populated with values.'
          end
        end
      else
        flash[:error] = "You do not have permission to perform this action."
      end
    else
      flash[:error] = "Unable to find inspection."
    end

    redirect_to :controller => 'qc/qc_inspection',
                :action     => 'edit_qc_inspection',
                :id         => id

  end

    # "Plugin" : Reads RFM measurements and populates measurement results for Sugar tests.
  def get_pretip_rfm_test_values
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      bin_no             = @qc_inspection.inspection_reference
      if authorise_for_web(program_name(qc_inspection_type_code),'edit')
        rfm_session = InstrumentsRfmSession.find(:first,
                                                :conditions => ['test_type = ? AND transaction_id = ?',
                                                                qc_inspection_type_code, bin_no],
                                                :order => 'created_on DESC')
        if rfm_session.nil?
          flash[:error] = "There are no RFM measurements for \"#{bin_no}\""
        else
          if msg = rfm_session.import_for( @qc_inspection )
            flash[:error] = "Unable to get test values. Error is #{msg}."
          else
            flash[:notice] = 'Tests have been populated with values.'
          end
        end
      else
        flash[:error] = "You do not have permission to perform this action."
      end
    else
      flash[:error] = "Unable to find inspection."
    end
    redirect_to :controller      => 'qc/qc_inspection',
                :action          => 'edit_qc_inspection',
                :id              => id

  end

end
