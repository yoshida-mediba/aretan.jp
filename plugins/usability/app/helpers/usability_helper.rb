module UsabilityHelper
  def us_email_issue_attributes(issue, user)
    items = []
    %w(author status priority assigned_to category fixed_version).each do |attribute|
      unless issue.disabled_core_fields.include?(attribute + "_id")
        items << [l("field_#{attribute}"), issue.send(attribute)]
      end
    end
    issue.visible_custom_field_values(user).each do |value|
      items << [value.custom_field.name, show_value(value, false)]
    end
    items
  end

  def us_available_progress_styles(object, field_name, current_value, options={})
    if object.is_a?(String) || object.is_a?(Symbol)
      object = object.to_s
    else
      object = model_name_from_record_or_class(object).param_key
    end

    select_options = [
        [l(:usability_pb_std),'std'],
        [l(:usability_pb_tiny),'tiny'],
        [l(:usability_pb_pie),'pie'],
        [l(:usability_pb_tor),'tor']
    ]
    if options.present? && options[:allow_blank]
      select_options.unshift ['x', '']
    end

    select_tag "#{object}[#{field_name.to_s}]", options_for_select(select_options, current_value)
  end
end