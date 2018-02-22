module Redmine::FieldFormat
  class Base
    class_attribute :ajax_supported
    self.ajax_supported = false

    attr_accessor :lb_only_current
  end

  class UserFormat
    self.ajax_supported = true

    def possible_values_records(custom_field, object=nil, like=nil, vals=nil)
      if object.is_a?(Array)
        projects = object.map {|o| o.respond_to?(:project) ? o.project : nil}.compact.uniq
        scope = User.active.joins(:members).where("#{Member.table_name}.project_id in (?)", projects.map { |p| p.project.id } + [0]).uniq
      elsif object.respond_to?(:project) && object.project
        scope = User.active.joins(:members).where("#{Member.table_name}.project_id = ?", object.project.id).uniq
      else
        scope = nil
      end

      return [] if scope.nil?

      if custom_field.user_role.is_a?(Array)
        role_ids = custom_field.user_role.map(&:to_s).reject(&:blank?).map(&:to_i)
        if role_ids.any?
          scope = scope.where("#{Member.table_name}.id IN (SELECT DISTINCT member_id FROM #{MemberRole.table_name} WHERE role_id IN (?))", role_ids)
        end
      end

      if vals.present?
        scope = scope.sorted.where(id: vals)
      elsif like.present?
        scope = scope.sorted.like(like)
      end

      if block_given?
        scope.each do |it|
          yield(it, it.id, it.name)
        end
      end

      scope.sorted
    end
  end

  class RecordList
    def cast_single_value(custom_field, value, customized=nil)
      if value.present? && customized.present? && customized.respond_to?(:acl_cf_casted_values) && customized.acl_cf_casted_values.present? && customized.acl_cf_casted_values[custom_field.id].present?
        i_value = value.to_i
        customized.acl_cf_casted_values[custom_field.id].find { |it| it && it.id == i_value }
      else
        target_class.find_by_id(value.to_i)
      end
    end

    def select_edit_tag(view, tag_id, tag_name, custom_value, options={})
      if custom_value.custom_field.format.ajax_supported && custom_value.custom_field.ajaxable
        options[:class] = options[:class].to_s + ' acl-select2-ajax'

        current_values = Array.wrap(custom_value.value)
        current_options = []
        if current_values.present?
          if self.respond_to?(:current_values_options)
            current_options = current_values_options(custom_value)
          else
            current_options = possible_custom_value_options(custom_value).select { |it| current_values.include?(it[1].to_s) } || []
          end
        end

        options[:data] ||= {}
        options[:data] = options[:data].merge({ url: view.url_for(controller: :custom_fields, action: :ajax_values, id: custom_value.custom_field.id),
                                                project_id: custom_value.customized.try(:project).try(:id).to_i,
                                                customized_id: custom_value.customized.try(:id).to_i
                                              })
        current_options = (custom_value.custom_field.multiple? ? [] : [['', '']]) + current_options unless custom_value.required?
        s = view.select_tag(tag_name, view.options_for_select(current_options, custom_value.value), options.merge(id: tag_id, multiple: custom_value.custom_field.multiple?, placeholder: ' '))
        if custom_value.custom_field.multiple?
          s << view.hidden_field_tag(tag_name, '')
        end
        s
      else
        super(view, tag_id, tag_name, custom_value, options)
      end
    end

    def current_values_options(custom_value)
      options = Array.wrap(custom_value.value)

      if custom_value.custom_field.format.ajax_supported && self.respond_to?(:possible_values_records)
        res = []
        possible_values_records(custom_value.custom_field, custom_value.customized, nil, options) { |it, id, value| res << [value, id] }
        res
      else
        target_class.where(id: options.map(&:to_i)).map { |o| [o.to_s, o.id.to_s] }
      end
    end
  end

  class AclDateTimeFormat < Unbounded
    add 'acl_date_time'
    self.form_partial = 'a_common_libs/formats/date_time'

    def cast_single_value(custom_field, value, customized=nil)
      if value.is_a?(String) && value.present? && ActiveRecord::Base.default_timezone == :utc
        value = value.strip + ' UTC'
      end
      Time.parse(value) rescue nil
    end

    def validate_single_value(custom_field, value, customized=nil)
      if (value =~ /^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}$|^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}$/ && (value.to_datetime rescue false))
        []
      else
        [::I18n.t('activerecord.errors.messages.not_a_date')]
      end
    end

    def edit_tag(view, tag_id, tag_name, custom_value, options={})
      view.text_field_tag(tag_name, User.current.acl_server_to_user_time(custom_value.value), options.merge(:id => tag_id, :size => 10)) +
          view.calendar_for_time(tag_id)
    end

    def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
      view.text_field_tag(tag_name, User.current.acl_server_to_user_time(value), options.merge(:id => tag_id, :size => 10)) +
          view.calendar_for_time(tag_id) +
          bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
    end

    def query_filter_options(custom_field, query)
      {:type => :acl_date_time}
    end

    def group_statement(custom_field)
      order_statement(custom_field)
    end

    def value_to_save(value)
      if (tm = User.current.acl_user_to_server_time(value))
        tm.strftime('%Y-%m-%d %H:%M:%S')
      end
    end
  end


  class AclPercentFormat < Numeric
    add 'acl_percent'
    self.form_partial = 'custom_fields/formats/acl_percent'
    field_attributes :edit_tag_style, :min_value, :max_value

    def cast_single_value(custom_field, value, customized=nil)
      value.to_f
    end

    def cast_total_value(custom_field, value)
      value.to_f.round(2)
    end

    def validate_single_value(custom_field, value, customized=nil)
      errs = super
      errs << ::I18n.t('activerecord.errors.messages.invalid') unless (Kernel.Float(value) rescue nil)

      if custom_field.min_value.present? && value.to_f < custom_field.min_value.to_f
        errs << ::I18n.t('activerecord.errors.messages.greater_than_or_equal_to', count: custom_field.min_value.to_f)
      end

      if custom_field.max_value.present? && value.to_f > custom_field.max_value.to_f
        errs << ::I18n.t('activerecord.errors.messages.less_than_or_equal_to', count: custom_field.max_value.to_f)
      end

      errs
    end

    def validate_custom_field(custom_field)
      errs = super

      errs << "#{::I18n.t(:field_custom_field_min_value)} #{::I18n.t('activerecord.errors.messages.invalid')}" if custom_field.min_value.present? && !(Kernel.Float(custom_field.min_value) rescue nil)
      errs << "#{::I18n.t(:field_custom_field_max_value)} #{::I18n.t('activerecord.errors.messages.invalid')}" if custom_field.max_value.present? && !(Kernel.Float(custom_field.max_value) rescue nil)

      if custom_field.min_value.present? && custom_field.max_value.present? && custom_field.min_value.to_f > custom_field.max_value.to_f
        errs << ::I18n.t(:error_acl_min_value_greater_then_max_value)
      end

      errs
    end

    def query_filter_options(custom_field, query)
      { type: :float }
    end

    def formatted_value(view, custom_field, value, customized=nil, html=false)
      casted = cast_value(custom_field, value, customized)
      if html && custom_field.url_pattern.present?
        texts_and_urls = Array.wrap(casted).map do |single_value|
          text = format_value(view, custom_field, single_value, html)
          url = url_from_pattern(custom_field, single_value, customized)
          [text, url]
        end
        links = texts_and_urls.sort_by(&:first).map {|text, url| view.link_to_if uri_with_safe_scheme?(url), text, url}
        links.join(', ').html_safe
      else
        Array.wrap(casted).map { |single_value| format_value(view, custom_field, single_value, html) }.join(', ').html_safe
      end
    end

    def format_value(view, custom_field, value, html=false)
      vl = view.number_with_precision(value, delimiter: ' ', strip_insignificant_zeros: true, precision: 2, separator: '.')
      if html && custom_field.edit_tag_style.present? && Redmine::Plugin.installed?(:usability)
        min = custom_field.min_value.present? ? custom_field.min_value.to_f : 0.0
        max = custom_field.max_value.present? ? custom_field.max_value.to_f : 100.0

        if max <= min
          percent = 100.0
        elsif min > value
          percent = 0
        elsif max < value
          percent = 100.0
        else
          percent = ((value.to_f - min) / (max - min)) * 100.0
        end

        view.progress_bar(percent, legend: "#{vl}#{' <span class="acl-unit">%</span>' if custom_field.edit_tag_style != 'tor'}".html_safe, progress_style: custom_field.edit_tag_style)
      elsif html
        "#{vl} <span class='acl-unit'>%</span>".html_safe
      else
        vl
      end
    end
  end
end