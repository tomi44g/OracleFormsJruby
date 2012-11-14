require 'java'
require 'frmjdapi.jar'
require 'fileutils'
include FileUtils

module M
  include_package 'oracle.forms.jdapi';

  olb = ObjectLibrary.open('../../src/libraries/W2KREF.olb')
  willow_std_tab = olb.object_library_tabs.find {|tab| tab.name == 'WILLOW_STDS'}
  current_record_va = willow_std_tab.tab_objects.find {|obj| obj.name == 'CG$CURRENT_RECORD'}

  Dir['../../src/forms/**/*.fmb'].each do |fmb_path|
    puts "Processing: #{fmb_path}"

    form = FormModule.open(fmb_path)
    needs_saving = false

    existing_cr_va = form.visual_attributes.find {|va| va.name == 'CG$CURRENT_RECORD'}
    if not existing_cr_va
      VisualAttribute.new(form, 'CG$CURRENT_RECORD', current_record_va)
      needs_saving = true
    elsif existing_cr_va.has_overridden_property? JdapiTypes.BACK_COLOR_PTID
      existing_cr_va.destroy
      VisualAttribute.new(form, 'CG$CURRENT_RECORD', current_record_va)
      needs_saving = true
    end

    blocks = form.blocks.select { |block| not block.name =~ /^(TOOLBAR|CALENDAR|PRINT|PRINT2|CALENDAR)$/ }

    blocks.each do |block|
      multirow_block = block.records_display_count > 1

      # remove the current record VA from block level - it makes checkboxes look bad
      if block.has_overridden_property? JdapiTypes.RECORD_VISUALATTRIBUTE_GROUP_NAME_PTID
        block.inherit_property JdapiTypes.RECORD_VISUALATTRIBUTE_GROUP_NAME_PTID
        needs_saving = true
      end

      if not block.record_visual_attribute_group_name.empty?
        block.record_visual_attribute_group_name = ''
        needs_saving = true
      end

      block.items.each do |item|
        # anly Text Items, Display Items and Pop Lists and only when do not have items_display set to 1
        if multirow_block
          item_should_have_crva = ([3, 6, 9].include? item.item_type) && (item.items_display == 0 or item.items_display > 1)
        else
          item_should_have_crva = false
        end

        if item_should_have_crva
           if (item.record_visual_attribute_group_name.empty? or item.record_visual_attribute_group_name != 'CG$CURRENT_RECORD')
             item.record_visual_attribute_group_name = 'CG$CURRENT_RECORD'
             needs_saving = true
           end
        else
          if item.has_overridden_property? JdapiTypes.RECORD_VISUALATTRIBUTE_GROUP_NAME_PTID # in most cases the property was just set on the form
            item.inherit_property JdapiTypes.RECORD_VISUALATTRIBUTE_GROUP_NAME_PTID # so getting the default value should nullify it
            if not item.record_visual_attribute_group_name.empty? # sometimes a multirow element is used and the default value is still pointing to current record
              item.record_visual_attribute_group_name = ''
            end
            needs_saving = true
          end
        end
      end
    end

    form.save fmb_path if needs_saving

    form.destroy
  end
end
