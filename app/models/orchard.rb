class Orchard < ActiveRecord::Base

  belongs_to :farm
  belongs_to :representative_orchard, :class_name => 'Orchard', :foreign_key => 'parent_orchard_id'

  #MM102014-add virtual variable commodity id
  attr_accessor :orchard_commodity_id, :commodity_code#, :commodity_description_long
  #===================================
  #   Validations
  #===================================
  validates_presence_of :orchard_code
  validates_presence_of :orchard_rmt_variety_id
  # validates_uniqueness_of :orchard_code

  def validate
    if self.new_record?
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = Orchard.find_by_farm_id_and_orchard_code_and_orchard_rmt_variety_id_and_is_group(self.farm_id,self.orchard_code,self.orchard_rmt_variety_id,self.is_group)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'orchard_code'")
    end
  end



  def integrate_representative_orchard_into_MAF
    begin
      rmt = RmtVariety.find_by_sql("select commodity_code from rmt_varieties where rmt_varieties.id = #{self.orchard_rmt_variety_id}")
      if rmt[0].commodity_code=='AP'

        http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
        request = Net::HTTP::Post.new("/select")
        parameters = {'method' => 'select', 'statement' => Base64.encode64("SELECT TOP 1 [Index_parcelle]
          FROM [productionv50].[dbo].[Parcelle]
          order by Index_parcelle desc")}
        request.set_form_data(parameters)
        response = http.request(request)

        if '200' == response.code
          res = response.body.split('resultset>').last.split('</res').first
          results = Marshal.load(Base64.decode64(res))
          index_parcelle=results[0]['Index_parcelle'].to_i
        else
          err = response.body.split('</message>').first.split('<message>').last
          error = " \"\". The http code is #{response.code}. Message: #{err}."
          raise error
        end

        parcelles = ActiveRecord::Base.connection.select_all("select distinct farms.farm_code, orchard_code, rmt_varieties.rmt_variety_code, track_slms_indicator_code
                                                  from orchards
                                                  inner join farms on farms.id =orchards.farm_id
                                                  inner join rmt_varieties on rmt_varieties.id = orchards.orchard_rmt_variety_id
                                                  inner join track_slms_indicators on track_slms_indicators.rmt_variety_code = rmt_varieties.rmt_variety_code
                                                  where farms.id = #{self.farm_id}
                                                  and orchards.id = #{self.id}
                                                  and rmt_varieties.id = #{self.orchard_rmt_variety_id}  and track_indicator_type_code='RMI'
                                                  order by farms.farm_code ")

        if(!parcelles.empty?)
          existing_pacel_clause = "where Code_parcelle='#{parcelles.map{|p| "#{p.orchard_code}_#{p.farm_code}_#{p.track_slms_indicator_code}" }.join("' or Code_parcelle='")}' "
          http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
          request = Net::HTTP::Post.new("/select")
          parameters = {'method' => 'select', 'statement' => Base64.encode64("SELECT *
            FROM [productionv50].[dbo].[Parcelle]
            #{existing_pacel_clause}")}
          request.set_form_data(parameters)
          response = http.request(request)

          if '200' == response.code
            res = response.body.split('resultset>').last.split('</res').first
            if(!Marshal.load(Base64.decode64(res)).empty?)
              return
            end

          else
            err = response.body.split('</message>').first.split('<message>').last
            error = " \"\". The http code is #{response.code}. Message: #{err}."
            raise error
          end
        end

        inserts = ['BEGIN TRANSACTION ']
        parcelles.each do |parcelle|
          #-------------------------------------------------------------------------------------------------------------------------------------------
          #-------------------------------------------------------------------------------------------------------------------------------------------
          http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
          request = Net::HTTP::Post.new("/select")
          parameters = {'method' => 'select', 'statement' => Base64.encode64("SELECT TOP 1 Code_parcelle
          FROM [productionv50].[dbo].[Parcelle]
          where Code_parcelle='#{parcelle.orchard_code}_#{parcelle.farm_code}_#{parcelle.track_slms_indicator_code}'")}
          request.set_form_data(parameters)
          response = http.request(request)

          if '200' == response.code
            res = response.body.split('resultset>').last.split('</res').first
            results = Marshal.load(Base64.decode64(res))
            if(results.empty?)
              index_parcelle+=1
              inserts.push("INSERT INTO [productionv50].[dbo].[Parcelle]([Code_parcelle],[Code_clone],[Code_adherent],[Nom_parcelle],[Surface],[Index_parcelle]) VALUES ('#{parcelle.orchard_code}_#{parcelle.farm_code}_#{parcelle.track_slms_indicator_code}'  ,'#{parcelle.track_slms_indicator_code}'  ,'#{parcelle.farm_code}' ,'#{parcelle.orchard_code}_#{parcelle.farm_code}_#{parcelle.track_slms_indicator_code}' ,1,#{index_parcelle});")
            end
          else
            err = response.body.split('</message>').first.split('<message>').last
            error = " \"\". The http code is #{response.code}. Message: #{err}."
            raise error
          end
          #-------------------------------------------------------------------------------------------------------------------------------------------
          #-------------------------------------------------------------------------------------------------------------------------------------------
        end
        inserts << ' COMMIT TRANSACTION'

        if inserts.length > 2
          http = Net::HTTP.new(Globals.bin_scanned_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
          request = Net::HTTP::Post.new("/exec")
          parameters = {'method' => 'insert', 'statement' => Base64.encode64(inserts.join)}
          request.set_form_data(parameters)
          response = http.request(request)

          if response.code != '200'
            err = response.body.split('</message>').first.split('<message>').last
            errmsg = " \"INSERT INTO [productionv50].[dbo].[Parcelle]\". The http code is #{response.code}. Message: #{err}."
            raise errmsg
          end
        end
      end
    rescue
      raise "SQL MF Automatic Integration returned an error: #{$!.message}"
    end
  end

end
