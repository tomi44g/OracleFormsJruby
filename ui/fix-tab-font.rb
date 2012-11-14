require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts "Processing: #{fmb_path} ..."

    form = FormModule.open(fmb_path)
    needs_saving = false

    canvases = form.canvases.select {|canvas| canvas.canvas_type == 4}                # Tab Canvas
    
    canvases.each do |canvas|

      if canvas.font_name.empty?
        puts "Canvas Before: #{canvas.name} - Font name:#{canvas.font_name}, size: #{canvas.font_size}, weight: #{canvas.font_weight}, style: #{canvas.font_style}, spacing: #{canvas.font_spacing}"
        canvas.font_name = 'MS Sans Serif'
        canvas.font_size = 800
        canvas.font_weight = 3
        canvas.font_style = 0
        canvas.font_spacing = 4
        needs_saving = true
      end      
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
