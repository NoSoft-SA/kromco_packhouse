# This class uses the SettingsLogic gem (https://github.com/binarylogic/settingslogic) to store client-specific settings.
#
# The settings are stored per client in a YAML file (config/client_settings.yml).
# Rails code can refer to a setting's value like this: ClientSettings.setting.
# Settings can be nested: ClientSetting.grouping.setting.
#
# This design uses an environment variable to store a key - the name of the client.
#
# To make the variable available system-wide:
# - add PACKHOUSE_CLIENT=name to /etc/environment
#
# For passenger to work:
# - add export PACKHOUSE_CLIENT=name to /etc/default/nginx
#
# For cron jobs to work:
# - add PACKHOUSE_CLIENT=name on a line at the top of the crontab.
#
# For development purposes,
# - add export PACKHOUSE_CLIENT=defaults in ~/.bashrc.
#
# If you want to change the value dynamically, make your command look like one of these:
# > PACKHOUSE_CLIENT=name script/server
# > PACKHOUSE_CLIENT=name script/runner 'puts "The company is #{ENV["PACKHOUSE_CLIENT"]}."'
#
class ClientSettings < Settingslogic

  # source "#{RAILS_ROOT}/config/client_settings.yml"
  # NB. source is specified like this so that EDI processing can load the file (RAILS_ROOT is not set).
  source File.join(File.expand_path(File.dirname(__FILE__) + '/../config'), 'client_settings.yml')

  raise MesScada::InfoError, "The environment variable \"PACKHOUSE_CLIENT\" has not been set." unless ENV['PACKHOUSE_CLIENT']
  namespace ENV['PACKHOUSE_CLIENT']

  load!

end
