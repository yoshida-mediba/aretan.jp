module Acl
  module ActsAsCustomizablePatch
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        class << self
          alias_method_chain :acts_as_customizable, :acl
        end
      end
    end

    module ClassMethods
      def acts_as_customizable_with_acl(options={})
        acts_as_customizable_without_acl(options)
        return if self.included_modules.include?(Acl::ActsAsCustomizablePatch::AclInstanceMethods)
        send :include, Acl::ActsAsCustomizablePatch::AclInstanceMethods
      end
    end

    module AclInstanceMethods
      def self.included(base)
        base.send :alias_method_chain, :custom_field_values=, :acl
        base.send :alias_method_chain, :custom_field_values, :acl
        base.send :alias_method_chain, :save_custom_field_values, :acl
        base.class_eval do
          attr_accessor :acl_cf_append, :acl_cf_delete
        end
      end

      def custom_field_values_with_acl
        Rails.logger.debug "\n ----------------------------- WARNING: a_common_libs - custom_field_values OVERWRITTEN COMPLETELY (Acl::Patches::Redmine::Acts::Customizable::InstanceMethodsPatch)"
        @custom_field_values ||= available_custom_fields.collect do |field|
          x = CustomFieldValue.new
          x.custom_field = field
          x.customized = self
          x
        end
      end

      def custom_field_values_with_acl=(values, action='=')
        Rails.logger.debug "\n ----------------------------- WARNING: a_common_libs - custom_field_values= OVERWRITTEN COMPLETELY (Acl::Patches::Redmine::Acts::Customizable::InstanceMethodsPatch)"


        Rails.logger.debug "\n !!!!!!!!!!!!!!!!#{action}!!!!!!!!!!!!!#{values.inspect}"
        values = values.stringify_keys

        custom_field_values.each do |custom_field_value|
          next if action != '=' && !custom_field_value.custom_field.multiple?
          key = custom_field_value.custom_field_id.to_s
          if values.has_key?(key)
            value = Array.wrap(values[key])
            value = value.first unless custom_field_value.custom_field.multiple?

            if value.is_a?(Array)
              value = value.reject(&:blank?).map(&:to_s).uniq
              if value.empty? && action == '='
                value << ''
              end
            else
              if custom_field_value.custom_field.format.respond_to?(:value_to_save)
                value = custom_field_value.custom_field.format.value_to_save(value)
              else
                value = value.to_s
              end
            end

            next if value.blank? && action != '='

            if action == '+'
              @acl_cf_append ||= {}
              @acl_cf_append[key] ||= []
              @acl_cf_append[key] = (@acl_cf_append[key] + value).uniq
              value = (custom_field_value.value + value).uniq
            elsif action == '-'
              @acl_cf_delete ||= {}
              @acl_cf_delete[key] ||= []
              @acl_cf_delete[key] = (@acl_cf_delete[key] + value).uniq
              value = custom_field_value.value - value
            end

            custom_field_value.value = value
            custom_field_value.acl_changed = true
          end
        end
        @custom_field_values_changed = true
      end

      def custom_field_values_append=(values)
        send :custom_field_values=, values, '+'
      end

      def custom_field_values_delete=(values)
        send :custom_field_values=, values, '-'
      end

      def save_custom_field_values_with_acl
        Rails.logger.debug "\n ----------------------------- WARNING: a_common_libs - save_custom_field_values OVERWRITTEN COMPLETELY (Acl::Patches::Redmine::Acts::Customizable::InstanceMethodsPatch)"
        custom_field_values.each do |custom_field_value|
          next unless custom_field_value.acl_changed

          skip_full_update = false
          if self.acl_cf_append.present? && self.acl_cf_append[custom_field_value.custom_field_id.to_s].present?
            self.acl_cf_append[custom_field_value.custom_field_id.to_s].each do |v|
              v = CustomValue.where(customized: self, custom_field_id: custom_field_value.custom_field.id, value: v).first_or_initialize({})
              v.save
            end
            skip_full_update = true
          end

          if self.acl_cf_delete.present? && self.acl_cf_delete[custom_field_value.custom_field_id.to_s].present?
            CustomValue.where(customized: self, custom_field_id: custom_field_value.custom_field.id)
                       .where(value: self.acl_cf_delete[custom_field_value.custom_field_id.to_s])
                       .delete_all
            skip_full_update = true
          end

          next if skip_full_update

          to_keep = []
          if custom_field_value.value.is_a?(Array)
            custom_field_value.value.each do |v|
              if custom_field_value.acl_value.present? && custom_field_value.acl_value[v].present?
                to_keep << custom_field_value.acl_value[v]
              else
                v = CustomValue.new(customized: self, custom_field: custom_field_value.custom_field, value: v)
                v.save
                to_keep << v.id
              end
            end

            CustomValue.where(customized: self, custom_field_id: custom_field_value.custom_field.id)
                       .where('id not in (?)', to_keep + [0])
                       .delete_all
          else
            target = custom_values.detect {|cv| cv.custom_field == custom_field_value.custom_field}
            target ||= custom_values.build(:customized => self, :custom_field => custom_field_value.custom_field)
            target.value = custom_field_value.value
            target.save
          end
        end
        self.custom_values.reload
        @custom_field_values_changed = false
        true
      end
    end
  end
end