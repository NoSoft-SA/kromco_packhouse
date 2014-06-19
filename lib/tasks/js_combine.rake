require 'tempfile'

namespace :js do
  desc "Combine home javascript src for production environment"
  task :combine_home => :environment do
    # list of files to combine
    libs = ['public/javascripts/field_show_popup.js', 
            'public/javascripts/lib/prototype.js', 
            'public/javascripts/src/scriptaculous.js', 
            'public/javascripts/src/effects.js', 
            'public/javascripts/src/dragdrop.js',
            'public/javascripts/tabs.js',
            'public/javascripts/popupwindow.js',
            'public/javascripts/session.js',
            'public/javascripts/progressbar.js',
            'public/javascripts/jquery.min.js',
            'public/javascripts/jquery-ui.min.js',
            'public/javascripts/jquery.fullscreen-min.js',
            'public/javascripts/search_form.js', 
            'public/javascripts/home_layout.js']
 
    # path to final combined file
    final = 'public/javascripts/home_all.js'
 
    # create single tmp js file
    tmp = Tempfile.open('homeall')
    libs.each {|lib| open(lib) {|f| tmp.write(f.read) } }
    tmp.rewind
 
    # move file
    %x[mv #{tmp.path} #{final}]
    FileUtils.chmod 0644, final
    puts "\n#{final}"
  end

  desc "Combine content javascript src for production environment"
  task :combine_content => :environment do
    # list of files to combine
    libs = ['public/javascripts/fields_seq.js', 
            'public/javascripts/separators.js', 
            'public/javascripts/popupwindow.js', 
            'public/javascripts/field_show_popup.js',
            'public/javascripts/lib/prototype.js',
            'public/javascripts/src/scriptaculous.js',
            'public/javascripts/src/effects.js',
            'public/javascripts/src/dragdrop.js',
            'public/javascripts/tabs.js',
            'public/javascripts/progressbar.js',
            'public/javascripts/window_finder.js',
            'public/javascripts/session.js',
            'public/javascripts/tablesort.js',
            'public/javascripts/jquery.min.js',
            'public/javascripts/jquery-ui.min.js',
            'public/javascripts/ui.multiselect.js',
            'public/javascripts/grid.locale-en.js',
            'public/javascripts/jqgrid_no_legacy.js',
            'public/javascripts/jquery.jqGrid.min.js',
            'public/javascripts/jqgrid_utils.js',
            'public/javascripts/jquery.collapse.js',
            'public/javascripts/jquery-ui-timepicker-addon.js',
            'public/javascripts/util.js', 
            'public/javascripts/jquery.fullscreen-min.js',
            'public/javascripts/search_form.js', 
            'public/javascripts/content_layout.js']
 
    # path to final combined file
    final = 'public/javascripts/content_all.js'
 
    # create single tmp js file
    tmp = Tempfile.open('contentall')
    libs.each {|lib| open(lib) {|f| tmp.write(f.read) } }
    tmp.rewind
 
    # move file
    %x[mv #{tmp.path} #{final}]
    FileUtils.chmod 0644, final
    puts "\n#{final}"
  end
end
