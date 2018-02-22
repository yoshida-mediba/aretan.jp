class EasyPerplexController < ApplicationController
  before_filter :require_login
  before_filter :check_ldap_installed, only: [:easy_perplex, :easy_perplex_actions]

  if Redmine::Plugin.installed?(:ldap_users_sync)
    include LdapApplicationHelper
    helper LdapApplicationHelper
  end

  def easy_perplex
    @unders = User.current.subordinates(true).sorted
    if (User.current.id == 69)
      @unders = User.find(10).subordinates(true).sorted
    end
    if (@unders.nil? || @unders == [])
      flash[:error] = l(:text_usability_easy_perplex_no_subordinates)
      @unders = nil
      return
    end
  end

  def easy_perplex_actions
    if (params[:user_id].to_i == 0)
      @clear = true
      return
    end

    @subordinate = User.active.where(id: params[:user_id].to_i).first
    if (@subordinate.nil?)
      flash[:error] = l(:text_usability_easy_perplex_wrong_user)
      return
    end
    if User.current.subordinates(true).where(id: @subordinate.id).blank?
      flash[:error] = l(:text_usability_easy_perplex_does_not_subordinate, user: view_context.link_to_user(@subordinate)).html_safe
      return
    end

    prepare_projects_for_actions
    prepare_departments_and_types_for_actions
  end

  private

  def check_ldap_installed
    unless Redmine::Plugin.installed?(:ldap_users_sync)
      flash[:error] = l(:text_usability_easy_perplex_ldap_was_not_installed)
      render action: :easy_perplex
    end
  end

  def prepare_projects_for_actions
    roles = Setting.plugin_usability[:easy_perplex_executor_roles]
    if roles && roles.is_a?(Array) && roles.any? && !roles[0].blank?
      @projects = Project.active.joins({ memberships: :roles }).where("#{Member.table_name}.user_id = ? and #{Role.table_name}.id in (?)", @subordinate.id, roles)
    else
      @projects = @subordinate.projects.active.visible
    end
    @projects = @projects.joins("LEFT JOIN #{Member.table_name} m on m.project_id = #{Project.table_name}.id and m.user_id = #{User.current.id}")
                         .select("#{Project.table_name}.*, case when m.id is null then 0 else 1 end as is_participant")
                         .uniq
  end

  def prepare_departments_and_types_for_actions
    @department = false
    return unless (Redmine::Plugin.installed?(:service_desk))

    @department = nil

    top_department = @subordinate.user_department.head_of_branch ? @subordinate.user_department : @subordinate.top_department

    if (sd = SdRequestType.where('user_department_id = ?', top_department.id)) != [ ]
      @department = { head: top_department, branch: @subordinate.user_department, types: sd }
    end
  end
end