class PDTFunctions

  def self.extract_pallet_num(pallet_num_entered)
    if (pallet_num_entered.length == 9 || pallet_num_entered.length == 18)

      return pallet_num_entered

    elsif pallet_num_entered.length == 11
      if (pallet_num_entered.slice(0, 2) == "46" || pallet_num_entered.slice(0, 2) == "47" || pallet_num_entered.slice(0, 2) == "48" || pallet_num_entered.slice(0, 2) == "49")
        return pallet_num_entered.slice(2..pallet_num_entered.length()-1)
      end

    elsif pallet_num_entered.length == 15
      if (pallet_num_entered.slice(0, 2) == "]C")
        return pallet_num_entered.slice(5..pallet_num_entered.length()-2)
      end
    end
   

    if (pallet_num_entered.length == 20 || pallet_num_entered.length == 21 || pallet_num_entered.length == 23)

      if (pallet_num_entered.length == 20)
        # is a 20 digit num
        pallet_num_entered = pallet_num_entered.slice(2..20)
      elsif (pallet_num_entered.length == 21)
        # is a 20 digit num
        pallet_num_entered = pallet_num_entered.slice(3..20)
      elsif (pallet_num_entered.length == 23)
        # is a 22 digit num
        pallet_num_entered = pallet_num_entered.slice(5..22)
      end

      if false #!pallet_num_entered.is_numeric?
        # Neither a 20 nor a 22 digit
        return "Invalid pallet number = " + pallet_num_entered.to_s + "  .........[20/22]"
      else

        return pallet_num_entered
      end
    end

    return "Invalid pallet number = " + pallet_num_entered.to_s + "  .........[!9/!18/!20/!22]"
  end

  def self.extract_carton_num(carton_num_entered)
    if (carton_num_entered.length == 13)
      carton_num_entered.chop!
    elsif (carton_num_entered.length != 12)
      return "Invalid ctn num must be 12 chars"
    end

    carton = Carton.find_by_carton_number(carton_num_entered.to_i)
    if carton.exit_reference && carton.exit_reference.upcase == 'SCRAPPED'
      return "Invalid. carton is scrapped"
    end
    return carton_num_entered.to_i
  end
end