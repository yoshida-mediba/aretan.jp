class ApiLogForPlugin < ActiveRecord::Base
  belongs_to :user

  def self.build_link_unread_log()
    link = "<span>#{l(:api_log_for_plugins_errors)}</span>"
    if Redmine::Plugin.installed?(:ajax_counters)
      link << User.current.ajax_counter('acl_not_served_log_count', {period: 0, css: 'count unread'})
    end
    link.html_safe
  end

end