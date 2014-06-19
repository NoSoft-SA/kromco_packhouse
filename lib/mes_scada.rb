# MES SCADA module
module MesScada
  # An exception for use in the MES SCADA system.
  # It allows for a nested exception.
  #
  # === Examples
  #
  # Used normally:
  # 
  #    Raise MesScada::Error, 'Something went wrong'
  #
  # Nested:
  #
  #    ...
  #    rescue IOError => e
  #      raise MesScada::Error, 'An IO error occurred', e
  #   end
  #
  #   ...
  #   rescue MesScada::Error => e
  #     if e.original.nil?
  #       puts e
  #     else
  #       puts e.original
  #     end
  #   end
  #
  class Error < StandardError
    attr_reader :original

    # Create the error with a nested error by default.
    # If there is no existing error, +original+ will be nil.
    def initialize(msg, original=$!)
      super(msg)
      @original = original;
    end

    # If there is a nested error, display both messages.
    def to_s
      if original.nil?
        super
      else
        "#{super} : #{original.class.name} : #{original.to_s}"
      end
    end

    # If there is a nested error, use its backtrace instead.
    def backtrace
      if original.nil?
        super
      else
        original.backtrace
      end
    end

  end
  class InfoError < MesScada::Error
  end
end

