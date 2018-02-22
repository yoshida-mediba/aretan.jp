module Usability
  module ApplicationHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :page_header_title, :usability
        alias_method_chain :progress_bar, :usability
        alias_method_chain :render_project_jump_box, :usability
        alias_method_chain :authoring, :usability
        alias_method_chain :time_tag, :usability
        alias_method_chain :javascript_heads, :usability
      end

    end

    module InstanceMethods

      def authoring_with_usability(created, author, options={})
        return authoring_without_usability(created, author, options) unless @use_static_date_in_history

        label = :label_usability_created_time_by
        if options[:label].present?
          if options[:label].to_s == 'label_added_time_by'
            label = :label_usability_created_time_by
          elsif options[:label].to_s == 'label_updated_time_by'
            label = :label_usability_updated_time_by
          else
            label = options[:label]
          end
        end
        l(label, author: link_to_user(author), age: time_tag([created, true])).html_safe
      end

      def time_tag_with_usability(date)
        return time_tag_without_usability(date) unless date.is_a?(Array)
        date = date.first
        if @project
          path = Redmine::VERSION.to_s >= '3.0.0' ? project_activity_path(@project, from: User.current.time_to_date(date)) : { controller: :activities, action: :index, id: @project, from: User.current.time_to_date(date) }
          link_to(format_time(date), path, title: format_time(date))
        else
          content_tag('abbr', format_time(date), title: format_time(date))
        end
      end

      def render_project_jump_box_with_usability
        if !Setting.respond_to?(:plugin_usability) || !Setting.plugin_usability[:dont_render_project_jump_box]
          return render_project_jump_box_without_usability
        end
        return
      end

      def page_header_title_with_usability
        return page_header_title_without_usability if !Setting.respond_to?(:plugin_usability) || !Setting.plugin_usability[:remove_project_page_header_breadcrumb]

        s = ''
        s << '<span>'
          if @project.nil? || @project.new_record?
            s << h(Setting.app_title)
          else
            s << h(@project.name.html_safe)
          end
        s << '</span>'
        s.html_safe
      end

      def progress_bar_with_usability(pcts, options={})
        pb_type = options[:progress_style] || (Setting.plugin_usability || {})[:usability_progress_bar_type] || 'std'

        unless %w(tiny tor pie).include?(pb_type)
          return progress_bar_without_usability(pcts, options)
        end

        pcts = [pcts, pcts] unless pcts.is_a?(Array)
        pcts = pcts.collect(&:round)
        pcts[1] = pcts[1] - pcts[0]
        pcts << (100 - pcts[1] - pcts[0])

        titles = options[:titles].to_a
        titles[0] = "#{pcts[0]}%" if titles[0].blank?

        radius = options[:radius] || 9
        legend = options[:legend] || "#{pcts[0]}%"
        font_size = options[:font_size] || 13
        border_width = options[:border_width] || 0.7

        case pb_type
          when 'tiny'
            html = "<div class='us-progress-body' title='#{titles[0]}'>"
            html << "<div class='us-progress' style='background: linear-gradient(to right, #A5E0AC #{pcts[0]}%, #FFF 1%); background: -webkit-linear-gradient(left, #A5E0AC #{pcts[0]}%, #FFF 1%);'>"
            html << "<span class='us-progr-text'>#{legend}</span></div></div>"
          when 'tor'
            r = 12.0
            rad = (2.0 / 100 * pcts[0].to_f - 0.5) * Math::PI ## 360 /  180 = 2
            to_x = Math::cos(rad) * r + r
            to_y = Math::sin(rad) * r + r
            large_arc = pcts[0].to_f > 50 ? '1' : '0'
            r = r.to_i.to_s
            html = '<div class="H us-tor-progr"><svg width="24" height="24">'
            if pcts[0] >= 100
              html << "<circle cx='#{r}' cy='#{r}' r='#{r}' fill='#f05f3b'></circle>"
            else
              html << "<circle cx='#{r}' cy='#{r}' r='#{r}' fill='#d0d0d0'></circle><path d='M #{r},#{r} L #{r},0 A #{r},#{r} 0 #{large_arc},1 #{to_x},#{to_y} Z' fill='#f05f3b'></path>"
            end
            html << "<circle cx='#{r}' cy='#{r}' r='9' fill='#fff'></circle>"
            html << "</svg></div><span class='us-tor-text'>#{legend}</span>"
          when 'pie'
            pie_id = "pie-#{Time.now.strftime("%Y%m%d%H%M%S")}-#{Redmine::Utils.random_hex(8)}"
            html = "<div id='#{pie_id}' class='pie-chart'></div>"
            html << '<script>'
            html << "RMPlus.Usability.makePieCharts($('##{pie_id}'), { radius: #{radius.to_f}, pcts: #{[pcts[0].to_f, pcts[2].to_f]}, border_width: #{border_width.to_f}, font_size: #{font_size}, legend: '#{escape_javascript(legend)}' });"
            html << '</script>'
        else
          html = ''
        end

        html.html_safe
      end

      def javascript_heads_with_usability
        tags = javascript_heads_without_usability
        if Setting.plugin_usability['disable_ajax_preloader']
          tags << "\n".html_safe + javascript_tag("$(document).ready(function() { var orig_setupAjaxIndicator = setupAjaxIndicator; function setupAjaxIndicator(){}; $('#ajax-indicator').remove(); });")
        end
        tags
      end
    end
  end
end
