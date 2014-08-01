module TextIn


  class Command

    attr_reader :schema,:parent

    def root
       @transformer
    end
    
    def initialize(transformer,schema,parent)
      @transformer = transformer
      @schema = schema
      @child = nil
      @parent = parent
    end


    #-------------------------------------------------------------------------------------------------------
    #Each command subclass should:
    #1]  extract the properties  needed for its own operation
    #2]  validate it's internal composition, i.e. that it contains valid sub commands
    #3]  Create subnode(s) and store it as child or other collection by calling Transformer.create_command
    #4]  Call new().parse on each child command
    #--------------------------------------------------------------------------------------------------------
    def parse
      
    end

    def validate
      
    end
    
    def execute
      
    end

    def parent_record?

      parent = @parent
      while parent
        if parent
          if parent.class.to_s == "TextIn::Record"
            return parent
          else
            parent = parent.parent
          end
        else
          return nil
        end
      end
    end

    #---------------------------------------------------------------------------------------
    #Move down through command hierarchy, until you find command that is of 'record' type
    #---------------------------------------------------------------------------------------
    def child_record?

    end

  end

  class Record < Command

    attr_reader :parent,:user_variables,:transformer,:record,:occurence,:has_record
    

    #---------------------------------------------------------------------------------------
    #Move up through command hierarchy, until you find first parent that is of 'record' type
    #---------------------------------------------------------------------------------------
    
    
    def parse
      
      @user_variables = Hash.new
      #must have attributes: identifier, size
      #if !@schema.attribute("size")
      if !@schema["size"]
        raise EdiValidationError, "No 'size' defined for record: " + @schema.to_s
      else
        #@size = @schema.attribute("size").to_s.to_i
        @size = @schema["size"].to_s.to_i
        #if @schema.attribute("occurence")
        if @schema["occurence"]
          #@occurence = @schema.attribute("occurence").to_s
          @occurence = @schema["occurence"].to_s
        end
        @raw_record = @transformer.next_record(@size)
        if !@raw_record ||@raw_record.length() < @size
          @has_record = false
          if !@occurence ||@occurence.index("1..")||@occurence == "1"
            if !at_least_one_record?
              raise EdiValidationError, "Record: " + @schema.to_s + " requires " + @size.to_s + " characters. Cursor: " + @transformer.get_cursor().to_s + ". Record provided: " + @raw_record.to_s
            end
          end
          @transformer.undo_next_record(@size)
          return nil
        end
      end
      
      #if !@schema.attribute("name")
      if !@schema["name"]
        return "No 'name' defined for record: " + @schema.to_s
      else
        #@name = @schema.attribute("name").to_s
        @name = @schema["name"].to_s
      end
      
      #if !@schema.attribute("identifier")
      if !@schema["identifier"]
        return "No 'identifier' defined for record: " + @schema.to_s
      else
        #@identifier = @schema.attribute("identifier").to_s
        @identifier = @schema["identifier"].to_s
      end

      if record_type? != @identifier
        @has_record = false
        @transformer.undo_next_record(@size)
        if !@occurence ||@occurence.index("1..")||@occurence == "1"
            if !at_least_one_record?
              raise EdiValidationError, "Record: " + @schema.to_s + " must occur at least once at this point of the document. Cursor: " + @transformer.get_cursor().to_s + ". Record provided: " + @raw_record.to_s
            else
              return
            end
        else
          return
        end
      else
        @has_record = true

      end
      
      #must have sub-nodes: transformer,fields

      #@schema.elements.each("*") do |e|
      @schema.xpath("*").each do |e|
        #case e.name
        case e.node_name
        when
          "transformer"
          #do nothing we'll load this later, after we're sure we have created a record
        when
          "fields"
         
          #@record = FixedLenRecord.new(@raw_record,e.get_elements("field"),@identifier)
          @record = transformer.new_text_record(@raw_record,e.xpath("field"),@identifier)          
        when
          "child","children"
          #@child = InTransformer.create_command(e,@transformer,e.name,self)
          @child = InTransformer.create_command(e,@transformer,e.node_name,self)
        else
          raise EdiValidationError, "Node: " + e.name + " not supported inside 'record' node. Can only be 'transformer' or 'child' or 'fields' "
        end
      end

      
      raise EdiValidationError, "Node: " + @schema.to_s + " has no fields defined" if ! @record

      #if @schema.get_elements('transformer')
      if @schema.xpath('transformer')
          #action_schema = @schema.get_elements('transformer')[0]
          action_schema = @schema.xpath('transformer')[0]
          if action_schema
              @action = Action.create_command(action_schema,@transformer,self,@record)
          else
             #transformer is optional
          end
      else
        #transformer is optional
      end


      
      
      if (!@occurence||@occurence.index('1..')) && !at_least_one_record?
        raise EdiValidationError, "Schema requires record type: " + @identifier + ", but current record is of type: " + record_type? + ". Cursor pos: " + @transformer.get_cursor.to_s + ". schema: " + @schema.to_s
      end

      #now parse inner nodes: first @action(transformer), then @child- if existing
      @action.parse() if @has_record  && @action
      @child.parse if @child && @has_record
      
    end

    def execute
      @action.execute() if @has_record  && @action
      @child.execute if @has_record && @child
      
    end

    def at_least_one_record?
      if @has_record
        return true
      elsif@parent && @parent.class.to_s == "TextIn::Repeater"
        return @parent.records.length() > 0
      else
        return false
      end
    end

    # Return the record type from the raw record for matching to
    # the identifier as defined in the schema definition.
    #
    # In the special case of a masterfile, always returns +masterfile+.
    def record_type?
      size = @transformer.identifier_size
      if @identifier == 'masterfile' || @identifier == 'uniform_file'
        @identifier
      else
        @raw_record.slice(0..size-1)
      end
    end
    
  end

  #------------------------------------------------------------------------------------------------------------------------
  #Sequence prescribes the order in which records must occur in the document. Specific records, may of cource be optional

  #-------------------------------------------------------------------------------------------------------------------------
  class Sequence < Command

    def more_occurences?
        #@occurence = @schema.attribute("occurence").to_s
        @occurence = @schema["occurence"].to_s
        if @occurence && @occurence.index("..n")
             if @seq_list.include?(@transformer.next_record_type?()) #@transformer.next_record_type?() == @seq_list[0]

               return true
             else
               return false
             end
        else
          return false
        end
    end
      #---------------------------------------------------------------------------------------------------------------------------------------------------
      #For each item in the prescribed sequence list, create a new record, passing in the record's own schema
      #Each newly created record will check internally whether it's identifier matches that of the passed-in schema, thus validating the defined sequence
      #----------------------------------------------------------------------------------------------------------------------------------------------------
      def parse
           get_sequence_list
           @commands = Array.new
           more_occurences = true
           while more_occurences
               @seq_list.each do |seq_item_name|
                 seq_item_schema = @seq_schemas[seq_item_name]
                    #command = TextTransformer.create_command(seq_item_schema,@transformer,seq_item_schema.name,self)
                    command = InTransformer.create_command(seq_item_schema,@transformer,seq_item_schema.node_name,self)
                    command.parse
                     @commands.push(command)

               end
               more_occurences = more_occurences?
           end



      end

     def execute
      @commands.each do |c|
        c.execute()
      end
    end

      def get_sequence_list
          @seq_list = Array.new  #the list created to enforce the correct order or sequence- hashes do not care about  order
          @seq_schemas = Hash.new
           #@schema.elements.each("*") do |e|
           @schema.xpath("*").each do |e|
              #case e.name
              case e.node_name
              when
                "record"
                 # @seq_list.push(e.attribute('identifier').to_s)
                 # @seq_schemas.store(e.attribute('identifier').to_s,e)
                 @seq_list.push(e['identifier'].to_s)
                 @seq_schemas.store(e['identifier'].to_s,e)

              else
                raise EdiValidationError, "Node: " + e.name + " not supported inside 'sequence' node. Can only be record "
              end
            end
      end
  end


  #---------------------------------------------------------------------------------------------------------------------------
  # The repeater command is created if the 'occurrence' attribute of a <record> node  stipulates 'zero-or-one to many'
  # The repeater is thus created with the same schema rules as the given record, but it creates many instances of the record,
  # as many as may occur in the document. 
  #---------------------------------------------------------------------------------------------------------------------------
  class Repeater < Command

    attr_reader :records


    #------------------------------------------------------------------------------------------------------------
    #  The active record schema defines an 'identifier'. Every time Record.new() is called the cursor
    #  is moved to the right with the defined size of current record type (as defined by active record schema)
    #  If the newly 'sliced' record has a different identifier than that defined by active schema, it means the
    #  repitition is over and the repeater is done
    #------------------------------------------------------------------------------------------------------------
    def parse
      @records = Array.new
      has_more_records = true
      while has_more_records
        record = Record.new(@transformer,@schema,self)
        record.parse
        if record.has_record
          @records.push(record)
        else
           has_more_records = false
        end
      end
 
    end

    def execute
      @records.each do |r|

        r.execute()
      end
    end

  end

  class Alternatives < Command

    
  end

  class Action < Command

    def Action.create_command(schema,transformer,parent,record)
      #return RubyAction.new(transformer,schema.get_elements("action")[0],parent,record)
      return RubyAction.new(transformer,schema.xpath("action")[0],parent,record)

    end

    def initialize(transformer,schema,parent,record)
      super(transformer,schema,parent)
      @record = record
         
    end

      

   
  end


  class RubyAction < Action

    def parse
      
      #@action_method = @schema.attributes['name'].to_s
      @action_method = @schema['name'].to_s
      raise EdiValidationError, "No name attribute defined for action" if ! @action_method
         
      require "edi/in/transformers/" + @transformer.flow_type + ".rb"
      @action_class_name = Inflector.camelize(@transformer.flow_type)
      if !@transformer.doc_events_handler
        @action_object = eval @action_class_name + ".new"
        @transformer.doc_events_handler = @action_object
      else
         @action_object = @transformer.doc_events_handler
       end
           
        
    end

    def execute
      @transformer.log "CALLING EDI RUBY ACTION: " + @action_class_name + "." + @action_method
      @action_object.send(@action_method,@record,@parent)
    end

  end

  class Transformer < Action

    def parse
        
    end

  end


  class InTransformer
    # require 'rexml/document'
    # include REXML
    include InTransformerSupport

    attr_accessor :flow_type,:doc_name,:doc_events_handler
    attr_reader :user_variables

    def identifier_size
      return @identifier_size
    end

    def get_cursor
      return @cursor
    end

    #-----------
    #-- LUKS ---
    #-----------
    def get_file_line_number
      @file_line_number
    end

    def set_file_contents(raw_text_array)
      @file_contents = raw_text_array.to_s
    end

    def get_file_contents
      @file_contents
    end

    def initialize(raw_text,flow_type,user = nil,ip = nil,doc_name = nil, in_or_out='in', schema=nil )

      #-----------
      #-- LUKS ---
      #-----------
      @file_line_number = 0
      @cursor = 0
      @flow_type = flow_type
      @raw_text = raw_text
      @xml_doc = nil
      @root_command = nil
      @user = user
      @ip = ip
      @doc_name = doc_name
      @user_variables = Hash.new
      @doc_events_handler = nil

      create_logger( in_or_out )

      if schema.nil?
        path = "edi/in/transformers/" + flow_type + ".xml"
        load_schema(path)
        validate_schema
      else
        @xml_doc = schema
        @identifier_size = @xml_doc.root["identifier_size"].to_i
        @root_identifier = @xml_doc.root["root_identifier"].to_s
      end

      find_root_command

      # #--------------------------------------------------------
      # #validate that schema file exists and is of corrrect type
      # #--------------------------------------------------------
      # if !File.exist?(path)
      #   raise EdiValidationError, "File: " + path + " does not exist"
      # else
      #   file = File.new(path)
      #   @xml_doc = Document.new(file)
      #   raise EdiValidationError, "schema: " + path + " is of type: " + @xml_doc.root.attributes["name"] + ". You asked for: " + flow_type if @xml_doc.root.attributes["name"] != flow_type
      # end

      # if !@xml_doc.root.attributes["identifier_size"]
      #   raise EdiValidationError, "identifier size is not defined"
      # else
      #   @identifier_size = @xml_doc.root.attributes["identifier_size"].to_s.to_i
      # end

      # if !@xml_doc.root.attributes["root_identifier"]
      #   raise EdiValidationError, "root identifier is not defined"
      # else
      #   @root_identifier = @xml_doc.root.attributes["root_identifier"].to_s
      # end

      # if 'masterfile' != @root_identifier
      #   root_doc_id = @raw_text.slice(0, @identifier_size)
      #   raise EdiValidationError, " schema requires doc(root) identifier: " + @root_identifier + " . Provided document has root doc type of " + root_doc_id if root_doc_id != @root_identifier
      # end

      # #-------------------------------------------------------------------------------------------------------
      # #Create root_node: can only be one element and must be of type: 'sequence' or 'alternatives' or 'record'
      # #-------------------------------------------------------------------------------------------------------
      # raise EdiValidationError, "in-map node must contain one and only one node: either 'sequence' or 'alternatives' or 'record' " if @xml_doc.root.get_elements("*").length != 1
      # @xml_doc.root.elements.each("*") do |e|
      #   case e.name
      #   when
      #     "record"
      #     @root_command = TextTransformer.create_command(e,self,e.name,nil)

      #   when
      #     "sequence"
      #     @root_command = TextTransformer.create_command(e,self,e.name,nil)
      #   when
      #     "alternatives"
      #     @root_command = TextTransformer.create_command(e,self,e.name,nil)
      #   else
      #     raise EdiValidationError, "Node: " + e.name + " not supported as root command. Must be 'sequence' or 'alternatives' or 'record' "
      #   end
      # end


    end


    def log(message,level = nil)
      @logger.write message,level
    end

    def get_logger
      @logger
    end

    def parse
      begin
        @logger.write "start parsing for flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1
        @root_command.parse()
        @logger.write "end parsing for flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1
        return nil

      rescue StandardError => error
        handle_error("parse", nil, error)
        return error

      end
    end

    def run
      begin
        @logger.write "start transforming flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1
        ActiveRecord::Base.transaction do
          @root_command.execute()
          @doc_events_handler.doc_transformed(self) if @doc_events_handler
          @logger.write "end transforming flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1
          return nil
        end
      rescue StandardError => error
        handle_error("execute", nil, error)
        return error
      end
    end

    def InTransformer.create_command(schema,transformer,node_name,parent)
      case node_name
      when "record"
        #if schema.attribute('occurence') && schema.attribute('occurence').to_s.index("..n")
        if schema['occurence'] && schema['occurence'].to_s.index("..n")
          return  Repeater.new(transformer,schema,parent)
        else
          return Record.new(transformer,schema,parent)
        end
      when "sequence"
        return Sequence.new(transformer,schema,parent)
      when "alternatives"
        return Alternatives.new(transformer,schema,parent)
      when "child","children"
        #return TextTransformer.create_command(schema.get_elements('*')[0],transformer,schema.get_elements('*')[0].name,parent)
        return InTransformer.create_command(schema.xpath('*')[0], transformer, schema.xpath('*')[0].node_name, parent)
      else
        raise EdiValidationError, "Node: " + node_name + " is not a known command "
      end

    end

    # Load the schem file from disk. Check for well-formedness and correct flow_type.
    def load_schema( path )
      if !File.exist?(path)
        raise EdiValidationError, "File: #{path} does not exist"
      else
        begin
          File.open( path ) do |file|
            @xml_doc = Nokogiri::XML(file) { |config| config.strict }
          end
        rescue Nokogiri::XML::SyntaxError => e
          raise EdiValidationError, "Schema #{path} is not well-formed: #{e}"
        end
        raise EdiProcessError, "Schema: #{path} is of type: #{@xml_doc.root["name"]}. You asked for: #{@flow_type}." if @xml_doc.root["name"] != @flow_type

        # file = File.new(path)
        # @xml_doc = Document.new(file)
        # raise EdiValidationError, "schema: " + path + " is of type: " + @xml_doc.root.attributes["name"] + ". You asked for: " + @flow_type if @xml_doc.root.attributes["name"] != @flow_type
      end
    end

    # Validate the schema. Valildate identifier size and root identifier/
    def validate_schema
      if !@xml_doc.root["identifier_size"]
        raise EdiValidationError, "identifier size is not defined"
      else
        @identifier_size = @xml_doc.root["identifier_size"].to_i
      end
      # if !@xml_doc.root.attributes["identifier_size"]
      #   raise EdiValidationError, "identifier size is not defined"
      # else
      #   @identifier_size = @xml_doc.root.attributes["identifier_size"].to_s.to_i
      # end

      if !@xml_doc.root["root_identifier"]
        raise EdiValidationError, "root identifier is not defined"
      else
        @root_identifier = @xml_doc.root["root_identifier"].to_s
      end
      # if !@xml_doc.root.attributes["root_identifier"]
      #   raise EdiValidationError, "root identifier is not defined"
      # else
      #   @root_identifier = @xml_doc.root.attributes["root_identifier"].to_s
      # end

      if 'masterfile' != @root_identifier && 'uniform_file' != @root_identifier
        root_doc_id = @raw_text.slice(0, @identifier_size)
        raise EdiValidationError, " schema requires doc(root) identifier: " + @root_identifier + " . Provided document has root doc type of " + root_doc_id if root_doc_id != @root_identifier
      end

    end

    # Check the schema to find the command to start executing.
    # Make sure the schema starts with node "sequence", "alternatives" or "record".
    def find_root_command
      raise EdiValidationError, "in-map node must contain one and only one node: either 'sequence' or 'alternatives' or 'record' " if @xml_doc.root.children.select {|n| n.elem? }.size != 1
      # raise EdiValidationError, "in-map node must contain one and only one node: either 'sequence' or 'alternatives' or 'record' " if @xml_doc.root.get_elements("*").length != 1
      # @xml_doc.root.elements.each("*") do |e|
      #   case e.name
        e = @xml_doc.root.first_element_child
        case e.node_name
        when
          "record"
          @root_command = InTransformer.create_command(e,self,e.name,nil)

        when
          "sequence"
          @root_command = InTransformer.create_command(e,self,e.name,nil)
        when
          "alternatives"
          @root_command = InTransformer.create_command(e,self,e.name,nil)
        else
          raise EdiValidationError, "Node: " + e.name + " not supported as root command. Must be 'sequence' or 'alternatives' or 'record' "
        end
      # end
    end
  end
  
  class CsvInTransformer < InTransformer
    def validate_schema
      super
      raise EdiValidationError, "csv delimiter is not defined" if(!@xml_doc.root["delimiter"])
    end

    def next_record_type?()
      return "uniform_file"
    end

    def next_record(size)
      record = @raw_text[@cursor]
      @cursor += 1
      @file_line_number += 1
      return record
    end

    def undo_next_record(size)
      @cursor -= 1
      @file_line_number -= 1
    end

    def new_text_record(raw_text,field_descriptors,record_type)
      CsvRecord.new(raw_text,field_descriptors,record_type,@xml_doc.root["delimiter"])
    end
        
  end
  
  class TextTransformer  < InTransformer

    def next_record_type?()
      return @raw_text.slice(@cursor..@cursor + @identifier_size - 1)
    end

    def next_record(size)
      record = @raw_text.slice(@cursor..@cursor + size -1)
      @cursor += size
      @file_line_number += 1
      return record
    end

    def undo_next_record(size)
      @cursor -= size
      @file_line_number += 1
    end

    def new_text_record(raw_text,field_descriptors,record_type)
      FixedLenRecord.new(raw_text,field_descriptors,record_type)
    end
  end
    
end

