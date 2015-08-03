rails = File.join Dir.getwd, 'config', 'environment.rb'
if File.exist?(rails) && ENV['SKIP_RAILS'].nil?
  require rails
  if defined? Rails.version # Rails 1.x does not have version
    if Rails.version[0..0] == "2"
      require 'console_app'
      require 'console_with_helpers'
    elsif Rails.version[0..0] == "3"
      require 'rails/console/app'
      require 'rails/console/helpers'
    else
      warn "[WARN] cannot load Rails console commands (Not on Rails2 or Rails3?)"
    end
  else
    require 'console_app'
    require 'console_with_helpers'
  end
end
