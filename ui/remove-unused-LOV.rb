require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  puts Dir.pwd
  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts '*'*80, "Processing: #{fmb_path} ..."

    form = FormModule.open(fmb_path)
    needs_saving = false

    code = ''
    referenced_lovs = []
    referenced_rgs = []

    form.program_units.each {|pu| code << pu.program_unit_text}
    form.triggers.each {|trg| code << trg.trigger_text}
    
    blocks = form.blocks.each do |block|
      #puts "Block: #{block.name}"
      block.triggers.each {|trg| code << trg.trigger_text}
      block.items.each do |item|
        #puts "Item: #{item.name}, lov_name: #{item.lov_name}"
        item.triggers.each {|trg| code << trg.trigger_text}
        if not item.lov_name.empty?
          referenced_lovs << item.lov_name
        end
        if not item.record_group_name.empty?
          referenced_rgs << item.record_group_name
        end
      end
    end

    code.gsub!(/(\/\*)(.*?)(\*\/)/m, '')                        # Block '/* xxx */' comments
    code.gsub!(/--.*/, '')                                      # Single line '-- xxx comments
    code.upcase!
    
    # Removing unused LOVs

    puts "Referenced LOVs: #{referenced_lovs.sort.inspect}"

    unused_lovs = form.getLOVs.collect {|lov| lov.name} # get All
    unused_lovs.delete_if {|lov| referenced_lovs.include? lov} # referenced by an item
    unused_lovs.delete_if {|lov| lov =~ /^(FILE_PATH|WEB_PRINTERS|REPORTS)$/ } # referenced in pll
    unused_lovs.delete_if {|lov| code =~ /\b#{Regexp.escape(lov)}\b/} # referenced anywhere in the code

    puts "Unused LOVs: #{unused_lovs.sort.inspect}"
    unused_lovs.each do |lov_name|
      lov = form.getLOVs.find {|lov| lov.name == lov_name}
      if lov
        puts "Removing LOV: #{lov.name} ..."
        lov.destroy
        needs_saving = true
      end
    end

    form.getLOVs.each {|lov| referenced_rgs << lov.record_group_name}

    # Removing unused Record Groups
    
    unused_rgs = form.record_groups.collect {|rg| rg.name}
    unused_rgs.delete_if {|rg| referenced_rgs.include? rg} # referenced by an item or lov
    unused_rgs.delete_if {|rg| rg =~ /^(FILE_PATH|WEB_PRINTERS|REPORTS)$/ } # referenced in pll
    unused_rgs.delete_if {|rg| code =~ /\b#{Regexp.escape(rg.upcase)}\b/} # referenced anywhere in the code

    unused_rgs.each do |rg_name|
      rg = form.record_groups.find {|rg| rg.name == rg_name}
      if rg
        puts "Removing Record Group: #{rg.name} ..."
        rg.destroy
        needs_saving = true
      end
    end

    form.save fmb_path if needs_saving

    form.destroy
  end
end
