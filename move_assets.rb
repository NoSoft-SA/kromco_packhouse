
time_interval =  (!ARGV[0]) ? 1 : ARGV[0].to_i



while (true)
 puts "in loop"	
  
   for i in 1..10 do
    begin
         puts "I is now #{i}"
     
    rescue
     puts "err: #{$!}"
    end
  end

  sleep(time_interval * 10)
end


