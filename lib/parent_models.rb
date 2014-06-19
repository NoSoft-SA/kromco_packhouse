
class ParentModels
  attr_accessor :parent_models_ids
  
  def initialize(model_name)
    @model_name = Inflector.singularize(model_name)
    @parent_models = {}
    get_parent_model_names_by_ids
  end

  def get_parent_model_names_by_ids
    klass = Inflector.camelize(@model_name).constantize

    klass.reflect_on_all_associations.each do |assoc|
      if assoc.options && assoc.options[:foreign_key]
        if assoc.options[:class_name]
          @parent_models[assoc.options[:foreign_key]] = Inflector.singularize(Inflector.tableize(assoc.options[:class_name]))
        else
          @parent_models[assoc.options[:foreign_key]] = assoc.name.to_s
        end
      end
    end
    @parent_models
  end
  
end
