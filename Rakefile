# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/switchtower.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
if Rake::VERSION.split('.').first.to_i < 10
  require 'rake/rdoctask'
else
  require 'rdoc/task'
end

require 'tasks/rails'
