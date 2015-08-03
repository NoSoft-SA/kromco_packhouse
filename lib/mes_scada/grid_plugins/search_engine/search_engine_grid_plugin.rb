module MesScada::GridPlugins

  module SearchEngine

    class SearchEngineGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        if column_name == "show_records"
          id_string = ""
          text = "show records"
          keys = record.keys
          keys.each do |key|
            val = ""
            if record[key].to_s.index(" ")!= nil
              val = record[key].to_s.gsub(" ","se2345se")
            else
              val = record[key].to_s
            end
            if key.to_s.upcase().index("COUNT") == nil && key.to_s.upcase().index("AVG") == nil && key.to_s.upcase().index("SUM") == nil && key.to_s.upcase().index("MIN") == nil && key.to_s.upcase().index("MAX") == nil
              if id_string != ""
                id_string += "!" + key.to_s + "-3457-" + val
              else
                id_string += key.to_s + "-3457-" + val
              end
            end
          end

          return make_link_window("http://#{@request.host_with_port}/reports/reports/show_records?id=#{id_string}", text)

        end
        cell_value
      end

    end

  end

end
