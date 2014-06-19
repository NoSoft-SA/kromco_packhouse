class RandomGenerator

    def initialize(sample_size, quantity_full_bins)
        @sample_size = sample_size
        @quantity_full_bins = quantity_full_bins
    end

    def generate_sequence_numbers
        array = Array.new
        if(@sample_size==1)
          array.push(1)
          return array
        end
        
        @sample_size.times do |s|
          position = rand(@quantity_full_bins+1)
          while(array.include?(position) || position == 0)
            position = rand(@quantity_full_bins+1)
          end
          array.push(position)
        end
#        i=0
#        number=0
#        while i < @sample_size
#            number = rand(@quantity_full_bins)
#            if array.empty? && number!=0
#                array.push(number)
#            elsif number!=0 && !array.include?(number)
#                array.push(number)
#            else
#                required=0
#                until required!=0 && !array.include?(required)
#                    required = rand(@quantity_full_bins)
#                end
#                array.push(required)
#            end
#            i=i+1
#        end
        return array
    end

end