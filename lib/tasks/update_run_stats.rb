class UpdateRunStats


  def call

    begin

    jobs = get_run_stats_jobs
    update_run_stats(jobs)
    delete_jobs(jobs)

    rescue
      err_entry = RailsError.new
      err_entry.description = $!
      err_entry.stack_trace = $!.backtrace.join("\n").to_s if $!
      err_entry.logged_on_user  = "run stats updater"
      err_entry.person          = "system"
      err_entry.error_type      = "rails back-end service"
      err_entry.create

      raise

    end



  end


  def get_run_stats_jobs

    return ActiveRecord::Base.connection.select_all("select * from run_stats_jobs")

  end


  def delete_jobs(jobs)

    log_query = "insert into run_stats_job_logs  ( production_run_id,cartons_printed,cartons_weight,rebins_printed,rebins_weight,bins_tipped,bins_tipped_weight,
                                          pallets_completed,logged_at,updated_at)
                 (select  production_run_id,cartons_printed,cartons_weight,rebins_printed,rebins_weight,bins_tipped,bins_tipped_weight,
                                          pallets_completed,logged_at,now() from run_stats_jobs where id in (#{jobs.map{|j|j.id}.join(",")})) "

    ActiveRecord::Base.connection.execute(log_query) if jobs.size > 0

    query = "delete from run_stats_jobs where id in (#{jobs.map{|j|j.id}.join(",")}) "
    puts query
    ActiveRecord::Base.connection.execute(query) if jobs.size > 0

  end


  def update_run_stats(jobs)
    cartons_printed = 0
    cartons_weight = 0
    rebins_printed = 0
    rebins_weight = 0
    bins_tipped = 0
    bins_tipped_weight = 0
    pallets_completed = 0

    jobs.each do |job|
      cartons_printed = job['cartons_printed'].to_i
      cartons_weight = job['cartons_weight'].to_f
      rebins_printed = job['rebins_printed'].to_i
      rebins_weight = job['rebins_weight'].to_f
      bins_tipped = job['bins_tipped'].to_i
      bins_tipped_weight = job['bins_tipped_weight'].to_f
      pallets_completed = job['pallets_completed'].to_i


      ActiveRecord::Base.connection.execute("update production_run_stats set cartons_printed = cartons_printed +  #{cartons_printed},
                                                                        cartons_weight = cartons_weight + #{cartons_weight},
                                                                        rebins_weight = rebins_weight + #{rebins_weight},
                                                                        rebins_printed = rebins_printed + #{rebins_printed},
                                                                        bins_tipped = bins_tipped + #{bins_tipped},
                                                                        bins_tipped_weight = bins_tipped_weight + #{bins_tipped_weight},
                                                                        pallets_completed = pallets_completed + #{pallets_completed}
                                          WHERE production_run_id = #{job['production_run_id']}")


    end


  end


end
