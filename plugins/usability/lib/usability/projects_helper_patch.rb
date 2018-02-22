module Usability
  module ProjectsHelperPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :project_settings_tabs, :usability
      end
    end

    module InstanceMethods
      def project_settings_tabs_with_usability
        if Setting.plugin_usability[:enable_ajax_project_settings]
          res = project_settings_tabs_without_usability.clone
          r = res.select { |it| it[:name] == 'info' || it[:name] == params[:tab] }

          res.each do |it|
            it[:partial] = 'projects/settings/us_blank_async' unless r.include?(it)
          end

          res
        else
          project_settings_tabs_without_usability
        end
      end
    end
  end
end