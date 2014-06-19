desc 'Clear sessions older than 24 hours'
task :clear_sessions => :environment do
  puts "Clearing sesions..."
  Session.sweep('24h')
  puts "...done!"
end