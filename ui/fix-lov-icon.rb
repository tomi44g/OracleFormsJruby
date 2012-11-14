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

    blocks = form.blocks.select {|block| not block.name =~ /^(TOOLBAR|CALENDAR|PRINT|PRINT2|WEBUTIL|CALENDAR)$/}
    
    blocks.each do |block|
      puts "Block: #{block.getName}"
      
      lov_buttons = block.items.select {|item| item.icon_filename =~ /^(listval|listval-b|calendar-b)$/i}
      
      lov_buttons.each do |lov_button|
        puts "Lov Button: #{lov_button.getName}"        

        # finding dest item for the LOV
        dest_item = nil

        # First try to find the dest item by the go_item in the trigger
        trigger = lov_button.triggers.find {|trigger| trigger.name == 'WHEN-BUTTON-PRESSED'}
        if trigger
          trigger_text = trigger.trigger_text
          trigger_text.gsub!(/(\/\*)(.*?)(\*\/)/m, '')                        # Block comments
          trigger_text.gsub!(/--.*/, '')                                      # Single line comments

          dest_item_name = trigger_text.upcase.scan(/(?:GO_ITEM\s*\(\s*')(.*?)(?:')/).flatten.last
          if dest_item_name
            #puts "Points to: #{dest_item_name}"
            dest_item_name.sub! /\w+\./, ''                                 # remove the block name
            dest_item = block.items.find {|item| item.name == dest_item_name}
          end
        end

        # Alternatively (the go_item may not be present in the trigger) find the corresponding item by LOV position
        if not dest_item
          text_items = block.items.select {|item| item.item_type == 9}
          closest_item, min_distance = nil, 99999

          text_items.each do |text_item|
            distance = Math.sqrt((lov_button.getXPosition - (text_item.getXPosition + text_item.width)).abs ** 2 + (lov_button.getYPosition - text_item.getYPosition).abs ** 2)
            #puts "Item: #{text_item.name}, distance: #{distance.to_s}"
            if distance < min_distance
              closest_item = text_item
              min_distance = distance
            end
          end
          if min_distance < 6
            dest_item = closest_item
          end
        end

        calendar_lov = false
        if dest_item
          if dest_item.data_type == 2 or dest_item.data_type == 5   # Date or DateTime
            calendar_lov = true
          end
        end

        if calendar_lov
          required_icon = 'calendar-b'
        else
          required_icon = 'listval-b'
        end
        
        if lov_button.icon_filename != required_icon
          lov_button.icon_filename = required_icon
          needs_saving = true
        end

        # fix LOV position
        if dest_item
          if not dest_item.canvas_name.empty? and not lov_button.canvas_name.empty? and dest_item.getXPosition > 0 and dest_item.getYPosition > 0 and lov_button.getXPosition > 0 and lov_button.getYPosition > 0
            ideal_x, ideal_y = dest_item.getXPosition + dest_item.width, dest_item.getYPosition
            distance = Math.sqrt((lov_button.getXPosition - ideal_x).abs ** 2 + (lov_button.getYPosition - ideal_y).abs ** 2)
            #puts "LOV: #{lov_button.name} ideal_x: #{ideal_x} ideal_y: #{ideal_y}, distance: #{distance}"
            if distance > 0 && distance < 10
              lov_button.setXPosition ideal_x
              lov_button.setYPosition ideal_y
              needs_saving = true
            end
          end
        end

        # fix LOV background
        if lov_button.has_overridden_property? JdapiTypes.FOREGROUND_COLOR_PTID
          lov_button.inherit_property JdapiTypes.FOREGROUND_COLOR_PTID
          needs_saving = true
        end
        if lov_button.has_overridden_property? JdapiTypes.BACK_COLOR_PTID
          lov_button.inherit_property JdapiTypes.BACK_COLOR_PTID
          needs_saving = true
        end
        if lov_button.has_overridden_property? JdapiTypes.FILL_PATTERN_PTID
          lov_button.inherit_property JdapiTypes.FILL_PATTERN_PTID
          needs_saving = true
        end
      end
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
