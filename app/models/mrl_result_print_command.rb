# To change this template, choose Tools | Templates
# and open the template in the editor.
require "app/models/pdt_transactions/pdt_business_functions/label_print_command.rb"
class MrlResultPrintCommand < LabelPrintCommand
  def set_print_data(*args)
    set_print_field(1, args[0])
    set_print_field(2, args[1])
    set_print_field(3, args[2])
    set_print_field(4, args[3])
    set_print_field(5, args[4])
    set_print_field(6, args[5])
  end
end
