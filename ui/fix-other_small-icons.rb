require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts "Processing: #{fmb_path}"

    form = FormModule.open(fmb_path)
    needs_saving = false

    blocks = form.blocks.select {|block| not block.name =~ /^(CALENDAR|PRINT|PRINT2|WEBUTIL|TOOLBAR|TOOLBAR2)$/}
    
    blocks.each do |block|
      #puts "Block: #{block.getName}"

      if not block.name =~ /TOOLBAR/      
        lov_buttons = block.items.select {|item| item.icon_filename =~ /^(insrec|delrec|edit|info)-b$/i}
      
        lov_buttons.each do |lov_button|
          puts "Block: #{block.getName}"
          puts "Lov Button: #{lov_button.getName}"        
          puts "icon_filename: #{lov_button.icon_filename}"        

          puts "Found small info button: #{block.name}.#{lov_button.name}"
          lov_button.icon_filename = lov_button.icon_filename.sub('-b', '_small-b')
          lov_button.width = 16
          needs_saving = true
        end
      end
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
