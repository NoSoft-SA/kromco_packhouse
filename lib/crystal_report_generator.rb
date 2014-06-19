class CrystalReportGenerator 
    include Config
    
    #Generates the crystal report with the help of XMLCrystalInterface java class. returns the string output(PDF formatted)
    #to the controller. The Controller will send the string output to the browser in the PDF format.
    
    def self.generate_report(xml_data, xml_schema, report_design)
        xml_temp_file_path = Dir.getwd+"/tmp/xml_tmp.xml"
        #create the temporary xml file for xml_data
        xml_file = File.new(xml_temp_file_path,"w")
        xml_file.print(xml_data)
        xml_file.close
        
        #set the class path for java class files and jar files
        interface_classpath = Dir.getwd+"/public/classes/crystal"
        case CONFIG['host']
            when /mswin32/
                Dir.foreach(Dir.getwd+"/public/jars/crystal") do |file|
                    interface_classpath << ";#{Dir.getwd}/public/jars/crystal/"+file if(file!='.' and file!='..' and file.match(/.jar/))
                    #puts file.to_s
                end
            else
                Dir.foreach(Dir.getwd+"/public/jars/crystal") do |file|
                    interface_classpath << ":#{Dir.getwd}/public/jars/crystal/"+file if(file!='.' and file!='..' and file.match(/.jar/))
                    #puts file.to_s
                end
        end
        
        result =""
        #pass the arguments and run the java class to generate the report
        IO.popen "java -cp \"#{interface_classpath}\"XmlCrystalInterface\"-x#{xml_temp_file_path}\"\"-f#{report_design}\"\"-s#{xml_schema}\"","w+b" do |pipe|
            #read the result pdf content from the stream
            result = pipe.read
            pipe.close
        end
        
        puts result.to_s
        
        interface_classpath.each do |file|
            puts file.to_s + "     \n"
        end
        
        #Delete the temporary xml file
        File.delete(xml_temp_file_path) if File.exists?(xml_temp_file_path)
        return result
    end
    
    #generate the xml schema for the query results
    def self.build_xml_schema(header_element, body_elements)
        # version="1.0" encoding="UTF-8"?
        # #version="1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
#        schema='<?xml>'
#        schema << '<xs:schema>' 
#        schema << '<xs:element name="report">'
#        schema << '<xs:complexType><xs:sequence>'
#        schema << '<xs:element maxOccurs="unbounded" name="#{header_element}" minOccurs="0">'
#        schema << '<xs:complexType><xs:sequence>'
#        body_elements.each do |element|
#            schema << "<xs:element name='#{element.to_s}' minOccurs='0'/>"
#        end
#        schema << "</xs:sequence><xs:complexType></xs:element>"
#        schema << "</xs:sequence></xs:complexType></xs:element></xs:schema>"
       #====================================================================
        schema='<?xml?>'
        schema += '<xs:schema>'
        
            schema += '<xs:element>'
                schema += '<xs:complexType>'
                    schema += '<xs:sequence>'
                        body_elements.each do |elem|
                            schema += '<xs:element/>'
                        end
                    schema += '</xs:sequence>'
                schema += '</xs:complexType>'
            schema += '</xs:element>'
        schema += '</xs:schema>'
        #===================================================================
        return schema
    end
 
end