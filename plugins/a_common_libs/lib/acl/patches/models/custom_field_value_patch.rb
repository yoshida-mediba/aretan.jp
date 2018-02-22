module Acl::Patches::Models
  module CustomFieldValuePatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :value_was, :acl
        alias_method_chain :value, :acl
        alias_method_chain :value=, :acl

        attr_accessor :acl_changed, :acl_value, :acl_trimmed_size, :acl_casted_value
      end
    end

    module InstanceMethods
      def value_with_acl
        return value_without_acl if @value_init

        @value_init = true
        if self.customized.present?
          if self.custom_field.multiple?
            values = self.customized.custom_values.select { |v| v.custom_field == self.custom_field }
            if values.empty?
              values << self.customized.custom_values.build(customized: self.customized, custom_field: self.custom_field)
            end
            @acl_value = {}
            vl = []
            values.each do |p|
              @acl_value[p.value] = p.id
              vl << p.value
            end
            @acl_trimmed_size ||= values.size
          else
            cv = self.customized.custom_values.detect { |v| v.custom_field == self.custom_field }
            cv ||= self.customized.custom_values.build(customized: self.customized, custom_field: self.custom_field)
            @acl_value = { cv.value => cv.id }
            vl = cv.value
            @acl_trimmed_size ||= 1
          end
          self.value_was = vl.dup if vl
          @value = vl
        end

        value_without_acl
      end

      def value_was_with_acl
        return value_was_without_acl if @value_init

        self.value
        value_was_without_acl
      end

      def value_with_acl=(vl, force=false)
        if force && !@value_init
          @value_init = true
          if self.custom_field.multiple?
            @acl_value = {}
            was_vl = []
            Array.wrap(vl).each do |p|
              @acl_value[p.value] = p.id
              was_vl << p.value
            end
          else
            vl = vl.first if vl.is_a?(Array)
            @acl_value = { vl.value => vl.id }
            was_vl = vl.value
          end
          vl = was_vl
          self.value_was = vl.dup if vl
        elsif !@value_init
          self.value
        end
        send :value_without_acl=, vl
      end
    end
  end
end