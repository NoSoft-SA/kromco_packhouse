class PoolGradedPsBin < ActiveRecord::Base

 belongs_to   :pool_graded_ps_summaries
 attr_accessor :weight_adjusted_plus,:weight_adjusted_minus,:total_calculated_weight,:total_adjusted_weight,:round_check,:rmt_bin_weight,:pesage_maf_weight,:maf_total_lot_weight ,:waste_weight ,
               :total_graded_weight_plus_round_check_plus_pesage_maf_weight_plus_waste ,:round_check_2

 #validates_presence_of :maf_class
 #validates_presence_of :maf_colour
 #validates_presence_of :maf_count
 #validates_presence_of :maf_weight
 #validates_presence_of :maf_article_count
 #validates_presence_of :maf_weight#,numericality:true
 #validates :maf_weight ,numericality:true

 def PoolGradedPsBin.get_maf_ps_bins(pool_graded_ps_summary,refresh=nil)
   maf_ps_bin_recordset=[]
   maf_tipped_qty = nil
   maf_total_lot_weight = nil
   ActiveRecord::Base.transaction do

     http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
     request = Net::HTTP::Post.new("/select")
     #parameters  = {'method' => 'select', 'statement' => Base64.encode64("select * from Viewlotapportresultatagreage ")} #where Numero_lot=#{@lot_number}
     parameters  = {'method' => 'select', 'statement' => Base64.encode64("
      select Numero_lot as maf_lot_number,Code_adherent as maf_farm_code,Code_clone as maf_rmt_code,
      Nom_article as maf_article,Nom_calibre as maf_count,Poids as maf_weight,Poids_total_calibre as maf_lot_weight,
      Nb_palox as maf_infeed_bin_qty
      FROM [productionv50].[dbo].[Viewlotapportresultat]
      WHERE Numero_lot = #{pool_graded_ps_summary.maf_lot_number} and  Nom_article <>  'Recycling'
      ORDER BY Numero_lot,Num_couleur,Num_calibre
      ")}

     request.set_form_data(parameters)
     response = http.request(request)
     puts "---\n#{response.code} - #{response.message}\n---\n"

     if '200' == response.code
       res     = response.body.split('resultset>').last.split('</res').first
       results = Marshal.load(Base64.decode64(res))
     else
       err = response.body.split('</message>').first.split('<message>').last
       #errmsg = "SQL Integration returned an error running \"select * from Viewlotapportresultatagreage \". The http code is #{response.code}. Message: #{err}." #where Numero_lot=#{@lot_number}
       errmsg = "SQL Integration returned an error running \"select Numero_lot as maf_lot_number,Code_adherent as maf_farm_code,Code_clone as maf_rmt_code,
      Nom_article as maf_article,Nom_calibre as maf_count,Poids as maf_weight,Poids_total_calibre as maf_lot_weight,
      Nb_palox as maf_infeed_bin_qty
      FROM [productionv50].[dbo].[Viewlotapportresultat]
      WHERE Numero_lot = #{pool_graded_ps_summary.maf_lot_number}
      ORDER BY Numero_lot,Num_couleur,Num_calibre \". The http code is #{response.code}. Message: #{err}."

       logger.error ">>>> #{errmsg}"
       raise errmsg
       return
     end

     raise "no bins  Palox"  if(results.empty?)


     maf_pool_graded_ps_bins=results

   if refresh
    delete_pool_graded_ps_summary_bins(pool_graded_ps_summary.id)
   end

   maf_pool_graded_ps_bins.each do |maf_bin|
     maf_article=maf_bin['maf_article'].split("_")
     inmemory_maf_bin=PoolGradedPsBin.new(:pool_graded_ps_summary_id=>pool_graded_ps_summary.id,:maf_farm_code=>maf_bin['maf_farm_code'],:maf_rmt_code=>maf_bin['maf_rmt_code'],:maf_article=>maf_bin['maf_article'],
                                          :maf_count=>maf_bin['maf_count'],:maf_weight=>maf_bin['maf_weight'],:maf_class=>maf_article[0],:maf_colour=>maf_article[1],:maf_article_count=>maf_article[2],:created_by=>ActiveRequest.get_active_request.user)
     maf_tipped_qty=maf_bin['maf_infeed_bin_qty']  if !maf_tipped_qty
     maf_total_lot_weight = maf_bin['maf_lot_weight'] if !maf_total_lot_weight
     maf_ps_bin_recordset << inmemory_maf_bin
   end
   end
   bin_grps=maf_ps_bin_recordset.group_by{|a|[a.maf_count,a.maf_class,a.maf_colour]}
   maf_pool_graded_ps_bin_recordset=[]
   for bin in bin_grps
     weight = 0
     for b in  bin[1]
      weight = weight +  b.maf_weight
     end
     representative_bin = bin[1][0]
     representative_bin.maf_weight = sprintf('%0.2f',weight ).to_f
     maf_pool_graded_ps_bin_recordset << representative_bin
   end
   return maf_pool_graded_ps_bin_recordset,maf_tipped_qty ,maf_total_lot_weight
 end

  def self.delete_pool_graded_ps_summary_bins(pool_graded_ps_summary_id)
    pool_graded_ps_summary_bins=PoolGradedPsBin.find_all_by_pool_graded_ps_summary_id(pool_graded_ps_summary_id)
    pool_graded_ps_summary_bins.each do |bin|
      bin.destroy
    end
  end



end