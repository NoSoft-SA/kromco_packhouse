
# require "edi/engine/record_padder.rb"

  class PoPre < RecordPadder

    def pre_process(text_line)
          processed_line = ""
          if text_line.slice(0..1)== "OL"
            if @location_loaded
               processed_line = "LT" + text_line.slice(2..text_line.length())
            else
              processed_line = "LF" + text_line.slice(2..text_line.length())
              @location_loaded = true
            end
          else
            processed_line = text_line
          end

          return processed_line

    end


  end


