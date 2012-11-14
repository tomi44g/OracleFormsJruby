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

    blocks = form.blocks.select {|block| not block.name =~ /^(TOOLBAR|CALENDAR|PRINT|PRINT2|CALENDAR|WEBUTIL)$/}

    blocks.each do |block|
      #puts "Block: #{block.getName}"

      items = block.items.select {|item| (not item.database_item?) and (item.bevel == 2) and (item.height <= 2) and (item.width <= 2) and not (item.canvas_name.empty?)}
      items.each do |item|
        puts "#{block.name}.#{item.name} w:#{item.width} h:#{item.height}, colour:#{item.back_color}"
        
        # if height set to 0 then it is impossible to select the item in Forms Builder Layout Editor
        if item.height > 1
          item.height = 1
          needs_saving = true
        end
        
        # setting the colour to gray8 the difference in luma between the item background and the canvas background is very small
        if item.back_color != 'gray8'
          item.back_color = 'gray8'
          needs_saving = true
        end
      end
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
