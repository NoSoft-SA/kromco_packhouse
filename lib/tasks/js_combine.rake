require 'tempfile'

namespace :js do
  desc "Combine home javascript src for production environment"
  task :combine_home => :environment do
    # list of files to combine
    libs = ['public/javascripts/field_show_popup.js',
            'public/javascripts/lib/prototype.js',
            'public/javascripts/src/scriptaculous.js',
#            'public/javascripts/src/effects.js',
#            'public/javascripts/src/dragdrop.js',
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
    libs = ['public/javascripts/lib/prototype.js',
            'public/javascripts/src/scriptaculous.js',
            'public/javascripts/fields_seq.js',
            'public/javascripts/separators.js',
            'public/javascripts/popupwindow.js',
            'public/javascripts/field_show_popup.js',
            'public/javascripts/tabs.js',
            'public/javascripts/progressbar.js',
            'public/javascripts/window_finder.js',
            'public/javascripts/session.js',
            'public/javascripts/tablesort.js',
            'public/javascripts/jquery.min.js',
            'public/javascripts/jquery-ui.min.js',
            'public/javascripts/ui.multiselect.js',
            'public/javascripts/jquery.collapse.js',
            'public/javascripts/jquery-ui-timepicker-addon.js',
            'public/javascripts/util.js',
            'public/javascripts/jquery.fullscreen-min.js',
            'public/javascripts/search_form.js',
            'public/javascripts/jquery.event.drag-2.2.js',
            'public/javascripts/content_layout.js',
            'public/javascripts/underscore.js',
            'public/javascripts/slick.core.js',
            'public/javascripts/slick.checkboxselectcolumn.js',
            'public/javascripts/slick.columnpicker.js',
            'public/javascripts/slick.pager.js',
            'public/javascripts/slick.dataview.js',
            'public/javascripts/slick.groupitemmetadataprovider.js',
            'public/javascripts/slick.remotemodel.js',
            'public/javascripts/slick.autotooltips.js',
            'public/javascripts/slick.cellcopymanager.js',
            'public/javascripts/slick.cellrangedecorator.js',
            'public/javascripts/slick.cellrangeselector.js',
            'public/javascripts/slick.cellselectionmodel.js',
            'public/javascripts/slick.rowselectionmodel.js',
            'public/javascripts/slick.formatters.js',
            'public/javascripts/slick.editors.js',
            'public/javascripts/slick.grid.js',
            'public/javascripts/slick.headermenu.js',
            'public/javascripts/ext.headerfilter.js',
            'public/javascripts/slgrid_utils.js',
            'public/javascripts/jquery.contextMenu.js',
            'public/javascripts/chosen.jquery.min.js']

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

  desc "Combine all javascript sources for production environment (home, content & content_jqgrid)"
  task :combine_all => :environment do
    Rake::Task["js:combine_home"].invoke
    Rake::Task["js:combine_content"].invoke
  end

end
