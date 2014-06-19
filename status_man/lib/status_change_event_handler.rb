class StatusChangeEventHandler
  def self.valid_status_change(from, to, object)

  end

  def self.calc_status(current_status, object)
    puts "on_status_change_action"
  end

  def self.on_status_change_action(current_status, new_status, object)
   puts "on_status_change_action"
  end

  def self.next_status(status_type, object)

  end
end