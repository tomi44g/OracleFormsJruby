require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils


module M
  include_package 'oracle.forms.jdapi';

  all_new_titles = File.read('lov_titles.txt').scan(/(.+)\t(.+)\t(.+)/)  # form_name, lov_name, new_title

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    form = FormModule.open(fmb_path)
    needs_saving = false

    lovs = form.getLOVs.select {|lov| not lov.auto_position?}
    lovs.each do |lov|
      lov.auto_position = true
      needs_saving = true
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
