require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts "*** Processing: #{fmb_path}"

    form = FormModule.open(fmb_path)
    needs_saving = false

    blocks = form.blocks.select {|block| not block.name =~ /^(TOOLBAR|CALENDAR|PRINT|PRINT2|WEBUTIL|CALENDAR)$/}
    
    blocks.each do |block|
      #puts "Block: #{block.getName}"
      
      items = block.items.select {|item| not item.canvas_name.empty?} 
      #items.delete_if {|item| item.item_type != 7} # Push Button
      
      items.each do |item|
        org_foreground_color = item.foreground_color.empty? ? 'black' : item.foreground_color.downcase
        org_back_color = item.back_color.empty? ? 'white' : item.back_color.downcase
        org_fill_pattern = item.fill_pattern.empty? ? 'transparent' : item.fill_pattern.downcase

        original_settings = "#{org_foreground_color}/#{org_back_color}/#{org_fill_pattern}"
          
        if original_settings == 'black/gray/transparent'
       
          if item.has_overridden_property? JdapiTypes.FOREGROUND_COLOR_PTID
            item.inherit_property JdapiTypes.FOREGROUND_COLOR_PTID
            needs_saving = true
          end
          if item.has_overridden_property? JdapiTypes.BACK_COLOR_PTID
            item.inherit_property JdapiTypes.BACK_COLOR_PTID
            needs_saving = true
          end
          if item.has_overridden_property? JdapiTypes.FILL_PATTERN_PTID
            item.inherit_property JdapiTypes.FILL_PATTERN_PTID
            needs_saving = true
          end

          new_foreground_color = item.foreground_color.downcase
          new_back_color = item.back_color.downcase
          new_fill_pattern = item.fill_pattern.downcase

          new_settings = "#{new_foreground_color}/#{new_back_color}/#{new_fill_pattern}"

          if original_settings != new_settings
            puts "#{block.name}.#{item.name} #{original_settings} => #{new_settings}"
          end
        end
      end
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
  
end
