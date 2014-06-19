class DocEventHandlers

  def log(message,level = nil)
    EdiHelper::transform_log.write message,level if EdiHelper::transform_log 
  end

  #event firing when document processing(transformation) is done
  def doc_transformed(root)

  end

  
end
