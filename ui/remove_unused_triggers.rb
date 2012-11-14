require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts '*'*80, "Processing: #{fmb_path}"

    form = FormModule.open(fmb_path)
    needs_saving = false
    
    triggers = form.triggers.select {|trigger| trigger.name =~ /^(KEY-CLRBLK|DO_ZOOMUP|DO_ZOOMDOWN)$/}
    
    triggers.each do |trigger|
      trigger.destroy
      needs_saving = true
    end
   
    form.save fmb_path if needs_saving

    form.destroy
  end
end
