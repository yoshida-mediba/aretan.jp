module Usability
  module AccountControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :login, :usability

        layout :us_layout
      end
    end

    module InstanceMethods
      def login_with_usability
        if !User.current.logged? && (Setting.plugin_usability || {})['replace_login_page']
          prepend_view_path File.join(Redmine::Plugin.find(:usability).directory, 'app', 'views', 'us_account_patched_views')
        end

        login_without_usability
      end

      def us_layout
        action_name.to_s == 'login' && !User.current.logged? && (Setting.plugin_usability || {})['replace_login_page'] ? 'rmp_layout' : 'base'
      end
    end
  end
end