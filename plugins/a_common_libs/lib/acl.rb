module Acl
end

require 'rmp_sql_ext'

if Redmine::VERSION.to_s >= '3.2.0'
  require_dependency 'redmine/field_format'
end

require_dependency 'acl/redmine/field_format'
require_dependency 'acl/helpers/extend_helper'
require_dependency 'acl/patches'

begin
  Acl::Utils::CssBtnIconsUtil.generate_css_file
rescue Exception => ex
  Rails.logger.info "WARNING: Cannot generate custom css for button icons #{ex.message}" if Rails.logger
end