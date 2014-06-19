class Progress

 def initialize()
  @message = ""
  @progress = 0
 
 end
 
 def update(message,progress)
 
  @message = message
  @progress += progress
 
 end
 
 def to_xml
   header = "<?xml version = '1.0' ?>"
   content = "<root>
		 <message>
		   '#{@message}'
		 </message>
         <progress>
           '#{@progress}'
         </progress>
		</root>"
   return header + content.gsub("'","")
 
 end
 


end