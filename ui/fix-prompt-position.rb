require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    #puts '*'*80, "Processing: #{fmb_path}"

    form = FormModule.open(fmb_path)
    needs_saving = false

    blocks = form.blocks.select {|block| not block.name =~ /^(TOOLBAR|CALENDAR|PRINT|PRINT2|CALENDAR|WEBUTIL)$/}

    blocks.each do |block|
      #puts "Block: #{block.getName}"

      items = block.items.select {|item| [2, 3, 6, 9].include? item.item_type} # Check Box, Display Item, List Item, Text Item
      items.delete_if {|item| not (10..16).include? item.height}               # Skip large text items, e.g. Notes
      items.delete_if {|item| item.prompt.empty?}
      items.delete_if {|item| item.canvas_name.empty?}
      items.delete_if {|item| item.prompt_attachment_edge != 0}                  # Only interested in prompts with PromptAttachmentEdge set to Start
      items.delete_if {|item| not (-1..6).include? item.prompt_align_offset}     # Negative attachment offset usually means that the prompt is really attached to the top
      items.delete_if {|item| not (-1..8).include? item.prompt_attachment_offset}
      items.each do |item|
        if item.items_display == 0
          records_display_count = block.records_display_count
        else
          records_display_count = item.items_display
        end

        if records_display_count == 1  # First Record unless the block displays only 1 record)
          #puts "Item: #{item.name}, Prompt: #{item.prompt.inspect}"
          if item.prompt != item.prompt.sub(/\s+\Z/, '')
            item.prompt = item.prompt.sub(/\s+\Z/, '')
            needs_saving = true
          end
          
          puts "#{form.name}\t#{block.name}.#{item.name}\t#{item.prompt.inspect}\t#{item.prompt_align}\t#{item.prompt_align_offset}\t#{item.prompt_attachment_offset}"
          
          if item.prompt_align != 2 # Center
            item.prompt_align = 2
            needs_saving = true
          end

          # set Align Offset to 0
          if item.has_overridden_property? JdapiTypes.PROMPT_ALIGN_OFFSET_PTID
            item.inheritProperty JdapiTypes.PROMPT_ALIGN_OFFSET_PTID
            needs_saving = true
          end
          if item.prompt_align_offset != 0
            item.prompt_align_offset = 0
            needs_saving = true
          end if
          
          if item.prompt_attachment_offset != 2
            item.prompt_attachment_offset = 2
            needs_saving = true
          end
        end
      end
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
