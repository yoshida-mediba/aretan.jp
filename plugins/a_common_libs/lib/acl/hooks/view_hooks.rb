module Acl
  class Hooks < Redmine::Hook::ViewListener
    render_on(:view_layouts_base_html_head, partial: 'hooks/a_common_libs/html_head')
    render_on(:view_my_account, partial: 'hooks/a_common_libs/favourite_project')
    render_on(:view_users_form, partial: 'hooks/a_common_libs/favourite_project')
    render_on(:view_custom_fields_form_upper_box, partial: 'hooks/a_common_libs/view_custom_fields_form_upper_box')
    render_on(:view_issues_history_journal_bottom, partial: "hooks/a_common_libs/journal_detail")
    render_on(:view_journals_update_js_bottom, partial: "hooks/a_common_libs/journal_detail_js")
  end
end
