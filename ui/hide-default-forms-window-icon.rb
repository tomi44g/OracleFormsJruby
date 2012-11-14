require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    form = FormModule.open(fmb_path)
    needs_saving = false
    puts "Processing #{form.name} ..."

    windows = form.windows.select {|window| true}
    windows.delete_if {|window| window.name =~ /WEBUTIL_HIDDEN_WINDOW/}
    windows.delete_if {|window| window.name =~ /^(ROOT|MAIN)_WINDOW$/}

    windows.each do |window|
      if window.icon_filename.empty?
        puts "Window: #{window.name} ..."
        window.icon_filename = 'transparent'
        needs_saving = true
      end
    end
   
    form.save fmb_path if needs_saving

    form.destroy
  end
end
