# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#ActiveSupport::Deprecation.silenced = true

# For devtools and report SQL, use coderay gem to show syntax-highlighted code.
begin
  require 'coderay'
  ENV['USE_CODERAY'] = '1'
rescue LoadError
rescue MissingSourceFile
end
# Try to silence "warning: Object#id will be deprecated; use Object#object_id" in log file.
Object.send(:undef_method, :id) if Object.respond_to?(:id)

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  config.action_mailer.delivery_method       = :smtp
  config.action_mailer.raise_delivery_errors = true
  #config.action_mailer.server_settings       = {
  config.action_mailer.server_settings       = {
      :address        => "mail.kromco.co.za",
      :domain         => "localhost",
      :port           => "25"
  }

  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  #  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format
# (all these examples are active by default):
Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
  inflect.irregular 'golf_club', 'golf_clubs'
#   inflect.uncountable %w( fish sheep )
end


YAML.add_domain_type("ActiveRecord,2010", "") do |type, val|
  klass = type.split(':').last.constantize
  YAML.object_maker(klass, val)
end

class ActiveRecord::Base
  def to_yaml_type
    "!ActiveRecord,2010/#{self.class}"
  end
end

class ActiveRecord::Base
  def to_yaml_properties
    ['@attributes']
  end
end

# Override truncate so that it works with Ruby 1.8.7 and Rails < 2.2
# NB ********* REMOVE WHEN UPGRADING RAILS *************************
module ActionView
  module Helpers
    module TextHelper
      def truncate(text, length = 30, truncate_string = "...")
        if text.nil? then
          return
        end
        l = length - truncate_string.chars.to_a.size
        (text.chars.to_a.size > length ? text.chars.to_a[0...l].join + truncate_string : text).to_s
      end
    end
  end
end


module ActionView
  module Helpers
    # Override select's include_blank so that it can use the text provided as its prompt instead of just a blank option.
    # NB ********* REMOVE WHEN UPGRADING RAILS *************************
    class InstanceTag
      private
        def add_options(option_tags, options, value = nil)
#          option_tags = "<option value=\"\"></option>\n" + option_tags if options[:include_blank]
          option_tags =  ("<option value=\"\">#{options[:include_blank].kind_of?(String) ? options[:include_blank] : ''}</option>\n") + option_tags if options[:include_blank]

          if value.blank? && options[:prompt]
            ("<option value=\"\">#{options[:prompt].kind_of?(String) ? options[:prompt] : 'Please select'}</option>\n") + option_tags
          else
            option_tags
          end
        end
    end

    module FormOptionsHelper

      # -----------> Start of changes to selects

      # Code in following 3 methods  ripped from Rails 2.3 to allow disabled options in dropdown.
      def extract_selected_and_disabled(selected)
        if selected.is_a?(Hash)
          [selected[:selected], selected[:disabled]]
        else
          [selected, nil]
        end
      end

      def option_value_selected?(value, selected)
        if selected.respond_to?(:include?) && !selected.is_a?(String)
          selected.include? value
        else
          value == selected
        end
      end

      def option_text_and_value(option)
        # Options are [text, value] pairs or strings used for both.
        if !option.is_a?(String) and option.respond_to?(:first) and option.respond_to?(:last)
          [option.first, option.last]
        else
          [option, option]
        end
      end

      # Redefined to_select_tag so that disabled options are handled.
      InstanceTag.class_eval do
        def to_select_tag(choices, options, html_options)
          html_options = html_options.stringify_keys
          add_default_name_and_id(html_options)
          value = value(object)
          selected_value = options.has_key?(:selected) ? options[:selected] : value
          #content_tag("select", add_options(options_for_select(choices, selected_value), options, selected_value), html_options)
          content_tag("select", add_options(options_for_select(choices, :selected => selected_value, :disabled => options[:disabled]), options, selected_value), html_options)
        end
      end

      # This redefines Rails 1.2.3's options_for_select by incorporating Rails 2.3's code for disabling options.
      # It is not elegant/efficient, it just works...
      def options_for_select(container, selected = nil)
        container = container.to_a if Hash === container

        selected, disabled = extract_selected_and_disabled(selected)

        options_for_select = container.inject([]) do |options, element|
          text, value = option_text_and_value(element)
          disabled_attribute = ' disabled="disabled"' if disabled && option_value_selected?(value, disabled)

          if !element.is_a?(String) and element.respond_to?(:first) and element.respond_to?(:last)
            is_selected = ( (selected.respond_to?(:include?) && !selected.is_a?(String) ? selected.include?(element.last) : element.last == selected) )
            if is_selected
              options << "<option value=\"#{html_escape(element.last.to_s)}\" selected=\"selected\"#{disabled_attribute}>#{html_escape(element.first.to_s)}</option>"
            else
              options << "<option value=\"#{html_escape(element.last.to_s)}\"#{disabled_attribute}>#{html_escape(element.first.to_s)}</option>"
            end
          else
            is_selected = ( (selected.respond_to?(:include?) && !selected.is_a?(String) ? selected.include?(element) : element == selected) )
            options << ((is_selected) ? "<option value=\"#{html_escape(element.to_s)}\" selected=\"selected\"#{disabled_attribute}>#{html_escape(element.to_s)}</option>" : "<option value=\"#{html_escape(element.to_s)}\"#{disabled_attribute}>#{html_escape(element.to_s)}</option>")
          end
        end

        options_for_select.join("\n")
      end

      # -----------> End of changes to selects

      def select(object, method, choices, options = {}, html_options = {})
        empty = choices.find { |c| c == "<empty>" || c.class == Array && c[0] == '<empty>' }
        if empty
          choices.delete(empty)
          options[:prompt] = '&lt;empty&gt;'
        end
        unless options[:sorted]
          choices.sort! do |x, y|
            if x.class.to_s == "Array" && y.class.to_s == "Array"
              x[0] && y[0] ? x[0] <=> y[0] : 0    # Sort on 1st element of array.
            elsif x.class.to_s == "String" && y.class.to_s == "String"
              if (x.to_i > 0 && y.to_i > 0)
                x.to_i <=> y.to_i                 # Sort integers
                else
                x <=> y                           # Sort strings
                end
              else
              0                                   # Sort as if x & y are equal
                end
              end
          end

          InstanceTag.new(object, method, self, nil, options.delete(:object)).to_select_tag(choices, options, html_options)


      end
    end
  end
end
# Include your application configuration below

# Bring in object.try from Rails 2.3.2.
# This allows you to get nil from a method called on a nil object (rather than a NoMethodError)
#
# e.g. IF department was optional for a User and you just wanted the department name if it existed, you could write:
# > user_with_dept.department.try(:department_name)
# => "IT"
# > user_without_dept.department.try(:department_name)
# => nil
#
# > user_without_dept.department.department_name
# => NoMethodError: You have a nil object when you didn't expect it!
#    The error occurred while evaluating nil.department_name
#
class Object
  # File activesupport/lib/active_support/core_ext/object/try.rb
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      #public_send(*a, &b) if respond_to?(a.first) # public_send introduced with Ruby 1.9
      send(*a, &b) if respond_to?(a.first)
    end
  end
end

class NilClass
  # File activesupport/lib/active_support/core_ext/object/try.rb
  def try(*args)
    nil
  end
end

