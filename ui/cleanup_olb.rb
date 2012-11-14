require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  referenced_objects = 'CG$CURRENT_RECORD,CG$GROUP_TITLE,CG$NOTES,CG$OTHER_RECORD'.split(',') # comma separated list of objejct in the olb which are referenced in fmb

  puts referenced_objects.count
  
  olb = ObjectLibrary.open('../../src/libraries/W2KREF.olb')
  tab = olb.object_library_tabs.find {|tab| tab.name == 'STD_LOVS'}
  
  objs = tab.tab_objects.select {|obj| true}
  
  objs.delete_if {|obj| referenced_objects.include? obj.name}
  
  objs.each do |obj|
    olb.remove_object obj
  end
  olb.save '../../src/libraries/W2KREF.olb'

end
