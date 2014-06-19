require 'rubygems'
require 'pathname'
require 'nokogiri'

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

# Change to the root of the rails app and work relative to that
Dir.chdir(Pathname(File.join(File.dirname(__FILE__), '../..')).cleanpath)
  
require 'edi/edi_helper'
require 'edi/in/record_padder'
require 'edi/edi_field_formatter'
require 'edi/raw_fixed_len_record'
require 'test/unit'

