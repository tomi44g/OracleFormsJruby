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

    blocks = form.blocks.select {|block| not block.name =~ /^(TOOLBAR|TOOLBAR2|CALENDAR|PRINT|PRINT2|CALENDAR|WEBUTIL)$/}

    blocks.each do |block|
      #puts "Block: #{block.getName}"

      items = block.items.select {|item| not item.canvas_name.empty? and item.icon_filename.empty?}
      items.each do |item|
        if item.font_name.empty? and item.height > 3 and item.width > 3
          puts "Item Font: #{block.name}.#{item.name} - Font name:#{item.font_name}, size: #{item.font_size}, weight: #{item.font_weight}, style: #{item.font_style}, spacing: #{item.font_spacing}"
          item.font_name = 'MS Sans Serif'
          item.font_size = 800
          item.font_weight = 3
          item.font_style = 0
          item.font_spacing = 4
          needs_saving = true
        end
        if item.prompt_font_name.empty? and not item.prompt.empty?
          puts "Item Prompt Font: #{block.name}.#{item.name} - Font name:#{item.prompt_font_name}, size: #{item.prompt_font_size}, weight: #{item.prompt_font_weight}, style: #{item.prompt_font_style}, spacing: #{item.prompt_font_spacing}"
          item.prompt_font_name = 'MS Sans Serif'
          item.prompt_font_size = 800
          item.prompt_font_weight = 3
          item.prompt_font_style = 0
          item.prompt_font_spacing = 4
          needs_saving = true
        end
      end
    end

    form.save fmb_path if needs_saving

    form.destroy
  end
end
