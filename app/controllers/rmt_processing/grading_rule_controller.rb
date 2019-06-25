class  RmtProcessing::GradingRuleController < ApplicationController

  def program_name?
    "grower_grading"
  end

  def bypass_generic_security?
    true
  end

  def upload_grading_rule_file
    @seasons = ActiveRecord::Base.connection.select_all("select distinct season_code,id from pool_graded_summaries"
               ).map{|x|[x['season_code'],x['id']]}.unshift("")

    @seasons
    @content_header_caption = "Select File"
    render :template => '/rmt_processing/grower_grading/upload_grading_rule_file.rhtml', :layout => 'content'
  end

  def submit_grading_file
    if params && params[:grading_file].blank?
      flash[:error] = "Choose a file"
      render :template => '/rmt_processing/grower_grading/upload_grading_rule_file.rhtml', :layout => 'content'
      return
    end
    begin
      x = ProcessGradingRuleFile.new(params[:grading_file],session[:user_id]['user_name'],params[:type],params[:season_id]).call
      if x
        flash[:error] = x
        render :template => '/rmt_processing/grower_grading/upload_grading_rule_file.rhtml', :layout => 'content'
        return
      else
        redirect_to_index("upload successful")
      end
    rescue
      raise $!
    end
  end






end