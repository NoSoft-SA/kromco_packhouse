

class State

   attr_accessor :parent

  def initialize(parent)
    @parent = parent
  end

  def get_screen(input)
  end


end



class InitState < State

  attr_accessor  :pin

  def get_screen(input)
    if !input
      return {:lines => ['please enter your pin'],:read_input => true}
    else
      pin = input.chomp!
      @parent.active_state = MainMenuState.new(self.parent)
      return {:lines => ["OK, no, I'm tired now, bye"]}
    end

  end


end



class MainMenuState < State

  attr_accessor  :pin

  def get_screen(input)
    if !input
      return {:lines => ['Weldone, correct pin'],:read_input => false}
      sleep 1
      self.parent.stop_running = true
    else

    end

  end



end




class AtmSession

  attr_accessor  :active_state, :stop_running

  def initialize()
    @active_state =  InitState.new(self)
    @stop_running = false

  end


  def run

    input = nil

    while ! @stop_running

      screen_def = @active_state.get_screen(input)
      input = build_screen(screen_def)

    end


  end



  def    build_screen(screen_def)

    input = nil

    screen_def[:lines].each do |line|
      puts line
    end

    if screen_def.has_key?(:read_input)
      input = gets

    end

    return input

  end


end



AtmSession.new().run()

