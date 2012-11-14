require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts '*'*3 + " Processing: #{fmb_path}"

    form = FormModule.open(fmb_path)
    needs_saving = false

    blocks = form.blocks.select {|block| not block.name =~ /^(TOOLBAR|CALENDAR|PRINT|PRINT2|CALENDAR|WEBUTIL)$/}

    blocks.each do |block|
      #puts "Block: #{block.getName}"

      items = block.items.select {|item| (not item.canvas_name.empty?) and (not item.prompt.empty?)}
      items.each do |item|
        new_prompt = item.prompt
        new_prompt.gsub! /\bVat\b/, 'VAT'
        new_prompt.gsub! /\bEdi\b/, 'EDI'
        new_prompt.gsub! /\bId\b/, 'ID'
        new_prompt.gsub! /\bOf\b/, 'of'
        new_prompt.gsub! /\bUom\b/, 'UOM'

        if item.prompt != new_prompt
          puts "#{block.name}.#{item.name} #{item.prompt.inspect} => #{new_prompt.inspect}"
          item.prompt = new_prompt
          needs_saving = true
        end
      end

      items = block.items.select {|item| (not item.canvas_name.empty?) and item.label == 'Ok'}
      items.each do |item|
        puts "#{block.name}.#{item.name} #{item.label.inspect} => #{'OK'.inspect}"
        item.label = 'OK'
        needs_saving = true
      end
    end
    
    form.save fmb_path if needs_saving

    form.destroy
  end
end
