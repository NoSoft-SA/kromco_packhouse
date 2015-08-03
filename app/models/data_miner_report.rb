# Deta miner report. Has a one-to-one relationship with the
# YAML files in +reports+ directory.
# Holds attributes describing the YAML report.
class DataMinerReport < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'author_id'

  # Ensure that all reports on disk are represented in the table.
  def self.sync_reports
    list_report_files.each do |file_name|
      grp = File.dirname(file_name) == '.' ? 'ungrouped' : File.dirname(file_name)
      if DataMinerReport.find_by_filename(file_name).nil?
        yml = YAML.load(File.read(File.join(Globals.get_reports_location, file_name)))

        grp = yml['default_report_index_group_name'] if yml['default_report_index_group_name']
        DataMinerReport.create(:group_name => grp, :filename => file_name, :report_name => File.basename(file_name, '.yml'))
      end
    end

    # Clear reports that do not exists on disk any more:
    DataMinerReport.find(:all).each do |report|
      unless File.exist?(File.join(Globals.get_reports_location, report.filename))
        logger.info ">>> Removed report from DataMinerReport because the file is no longer on disk: #{report.filename}."
        report.destroy
      end
    end
  end

  # Returns an Array of yml filenames including their relative paths.
  def self.list_report_files
    ymlfiles = File.join(Globals.get_reports_location, "**", "*.yml")
    Dir.glob( ymlfiles ).map {|l| l.split('/')[1..99].join('/')} # Remove top-level of path.
  end

  # Go through all reports on disk and update the group name if a default is present.
  def self.reset_group_names_from_files
    list_report_files.each do |file_name|
      dm = DataMinerReport.find_by_filename(file_name)
      unless dm.nil?
        yml = YAML.load(File.read(File.join(Globals.get_reports_location, file_name)))
        if yml['default_report_index_group_name']
          dm.group_name = yml['default_report_index_group_name']
          dm.save!
        end
      end
    end
  end

  # Return an Array of the column names from the query.
  def columns_in_order
    yml   = YAML.load(File.read(File.join(Globals.get_reports_location, self.filename)))
    sql   = yml['query'].gsub("\n", ' ')
    if sql.include? 'SUBQ'
      raise MesScada::Error, 'Currently cannot re-order a report that includes a subquery.'
    end

    match = sql.match(/\A\s*select\s?(.+)(\sfrom\s)/mi)
    cols  = match.nil? ? nil : match[1].gsub(/\w+\s?\([^\)]+?,{1}.+?\)/, 'HIDEFUNC').split(',').map {|c| c.split('.').last.split(' ').last }
    grid_configs = yml['grid_configs'] || {}
    column_captions = grid_configs['column_captions'] || {}
    cols.map {|col| column_captions[col] || col }
  end

  # Return the parts of the query in an Array.
  # The parts are: Select part (SELECT string), Columns (array of column definitions),
  # From part (FROM string) and the rest of the query (everything after the FROM as a string)
  def query_parts
    parts = []
    yml   = YAML.load(File.read(File.join(Globals.get_reports_location, self.filename)))
    sql   = yml['query'].gsub("\n", ' ')
    match = sql.match(/\A\s*select\s?(.+)(\sfrom\s)/mi)
    unless match.nil?
      sel_part  = match[0].sub(match[1],'').sub(match[2], '')
      cols_part = match[1]
      from_part = match[2]
      rest      = sql.sub("#{sel_part}#{cols_part}#{from_part}", '')
      parts << sel_part.strip
      parts << cols_part.strip.split(',').map {|a| a.strip } # NEEDS TO HANDLE subselects/functions with , in them..
      parts << from_part.strip
      parts << rest.strip
    end
    parts
  end

  # Rewrite the yml file with its query columns in a new sequence.
  # The original file is copied to tmp/backups first.
  def re_order_query( new_order )
    curr = self.query_parts
    new_cols = []
    new_order.each do |index|
      new_cols << curr[1][index]
    end
    new_query = "#{curr[0]} #{new_cols.join(', ')} #{curr[2]} #{curr[3]}"

    bkp_path  = [RAILS_ROOT, 'tmp', 'backups']
    bkp_path  << File.dirname(self.filename) unless File.dirname(self.filename) == '.'
    FileUtils.mkdir_p(File.join(bkp_path))
    FileUtils.cp(File.join(Globals.get_reports_location, self.filename), File.join(RAILS_ROOT, 'tmp', 'backups', self.filename ) )

    lines = File.readlines(File.join(Globals.get_reports_location, self.filename))
    lines.each_with_index {|l,i| if l =~ /\Aquery:/ then lines[i] = "query: #{new_query}\n"; break; end }
    File.open(File.join(Globals.get_reports_location, self.filename), 'w') { |f| f << lines.join }
  end

end
