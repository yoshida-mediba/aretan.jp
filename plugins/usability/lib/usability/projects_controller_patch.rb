module Usability
  module ProjectsControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :include, ProjectsHelper

      base.class_eval do
        alias_method_chain :settings, :usability
      end
    end

    module InstanceMethods
      def settings_with_usability
        @us_add_async_tabs = Setting.plugin_usability[:enable_ajax_project_settings]

        if request.get? && request.xhr? && params[:tab].present?
          @us_async_tab = project_settings_tabs_without_usability.find { |it| it[:name] == params[:tab] }
        end
        settings_without_usability
      end
    end
  end
end