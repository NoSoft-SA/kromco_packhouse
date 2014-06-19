# == quick_schema_setup.rb
#
# Helper tool for generating edi transformer schema fields.
#       
# Read a spreadsheet that has been populated from a Paltrack spec and
# create the xml field definitions for the schema.
#
# The spreadsheet can have the following headings in the first row:
#   FIELD NAME |TYPE |SIZE |FROM |TO |COMMENTS |FORMAT |DEFAULT |REQUIRED
#
# Only the first 3 cols and the last 3 cols are used by this script:
#
# The FORMAT column can be any of the values described in EdiFieldFormatter
# or a valid ruby +sprintf+ format.
#
# The DEFAULT column can contain any applicable default value.
# If the DEFAULT is 0 and the FORMAT is ZEROES, the field will be filled
# to its required length with zeroes.
#
# The REQUIRED column only needs an N if the field is not required.
# Blank or Y imply that the field is required.
#
# Tries to guess the correct column width from the SIZE given:
#   5.2                                        -> 5
#   -5.2                                       -> 6
#   blank and TYPE is date                     -> 8
#   blank and TYPE has hour and minute         -> 5
#   blank and TYPE has hour and minute and sec -> 8
# Always check the generated size against the spec!
#
# === Usage
#   ruby quick_schema_setup.rb path_to/schema_spec.ods
# or
#   ruby quick_schema_setup.rb path_to/schema_spec.xls
# (Requires the ROO gem)

require 'rubygems'
require 'roo'
require 'enumerator'

fname = ARGV[0]

if File.extname(fname).downcase == '.xls'
  oo = Excel.new(fname)
else
  oo = Openoffice.new(fname)
end
oo.default_sheet = oo.sheets.first

col_name = 'none'
col_type = 'none'
col_size = 'none'
col_fmt  = 'none'
col_def  = 'none'
col_req  = 'none'
('A'..'P').each do |l|
  if oo.celltype(1, l) == :string
    case oo.cell(1, l).upcase
    when 'FIELD NAME'
       col_name = l;
    when 'TYPE'
       col_type = l;
    when 'SIZE'
       col_size = l;
    when 'FORMAT'
       col_fmt = l;
    when 'DEFAULT'
       col_def = l;
    when 'REQUIRED'
       col_req = l;
    end
  end
end
[col_name,col_type,col_size,col_fmt,col_def,col_req].select{|c| c == 'none'}.each {|col| puts "Column missing"; exit;}

puts "Processing \"#{File.basename fname}\":\n\n"
start_row = 2

ar = []

start_row.upto(oo.last_row) do |row|
	fn = oo.cell(row, col_name)
	fn.gsub!(' ', '_')
	fn.squeeze!('_')
	if oo.cell(row, col_size).nil?
		if oo.cell(row, col_type).downcase == 'date'
			st = '8'
		else
			if oo.cell(row, col_type).downcase.include?( 'hour' ) &&
				 oo.cell(row, col_type).downcase.include?( 'minute' )
				if oo.cell(row, col_type).downcase.include?( 'sec' ) &&
					st = '8'
				else
					st = '5'
				end
			else
				st = '0'
			end
		end
	else
		st = oo.cell(row, col_size).to_s
	end
	st.gsub!(/.0$/, '') # Remove trailing '.0'
	sz = 0
	st.scan(/\d+|-|\./).each {|a| if a =~ /\D/ then sz += 1; else sz += a.to_i; end }
	
	s = "<field name=\"#{fn.downcase}\" size=\"#{sz}\""
	unless oo.cell(row, col_fmt).nil? || oo.cell(row, col_fmt).empty?
		s << " format=\"#{oo.cell(row, col_fmt)}\""
	end
	unless oo.cell(row, col_def).nil? || oo.cell(row, col_def).empty?
		s << " default=\"#{oo.cell(row, col_def)}\""
	end
	unless oo.cell(row, col_req).nil? || oo.cell(row, col_req).empty? || oo.cell(row, col_req) == 'Y'
		s << " required=\"false\""
	end
	s << ' />'
	ar << s
end
puts ar.join("\n")
