class PdtException < StandardError
  attr_accessor :pdt_errors

  def initialize(errors)
    @pdt_errors = errors
  end
end