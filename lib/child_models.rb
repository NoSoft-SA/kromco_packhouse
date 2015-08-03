# From a table name, generate an array of all the has_many,
# has_one & has_and_belongs_to_many relationships
class ChildModels
  attr_accessor :child_models_array

  def initialize(model_name)
    @child_models_array = []
    get_child_models( model_name )
  end

  # Turn the table name into the model class and interrogate it for
  # the relations.
  def get_child_models( model_name )
    klass   = Inflector.classify(model_name).constantize
    assocs  = klass.reflect_on_all_associations(:has_many)
    assocs += klass.reflect_on_all_associations(:has_one)
    assocs += klass.reflect_on_all_associations(:has_and_belongs_to_many)

    assocs.each do |assoc|
      opts = assoc.options.dup
      opts.delete(:dependent)
      @child_models_array << {:table => assoc.name.to_s}.merge(opts)
    end

  rescue StandardError => e
    raise MesScada::Error, 'ChildModels cannot be discovered'
  end

end
