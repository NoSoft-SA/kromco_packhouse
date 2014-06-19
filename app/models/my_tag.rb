class MyTag < ActiveRecord::Base
    
  #============================
  #	 Validations declarations:
  #============================
  validates_presence_of :tag_name
  #validates_uniqueness_of :tag_name
  
  def validate
     is_valid = true
     if self.new_record? && is_valid
        validate_uniquenes_of_tag_name 
     end
  end
  
  def get_errors
    return @model_errors
  end
  
  def validate_uniquenes_of_tag_name
     test_tag = MyTag.validate_tag_name(self.tag_name, self.user_name)
     if test_tag.length() != 0
        errors.add_to_base("The tag name must unique. You have a tag with this name!")
     end
  end
  
  private
  def self.validate_tag_name(tag_name, user_name)
      test_tag_name = MyTag.find_by_sql("select * from my_tags where tag_name = '#{tag_name}' and user_name = '#{user_name}'")
     return test_tag_name
  end
  
end