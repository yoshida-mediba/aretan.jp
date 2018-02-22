module Usability
  module WikiFormattingPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        class << self
          alias_method_chain :to_html, :usability
        end
      end
    end
  end
  module ClassMethods
    def to_html_with_usability(format, text, options = {})
      orig_parse = to_html_without_usability(format, text, options)
      replace_parse = ""
      replace_parse += orig_parse

      if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
        host = $2
      else
        host = Setting.host_name
      end

      if (Setting.plugin_usability || {})['replace_link_textilizable']
        # old (<a.+?href="http[s]{0,1}:\/\/[^\/]+\/issues\/(\d+)[^"]+">(.+?)<\/a>)
        orig_parse.scan(/(<a[^>]+href="http[s]{0,1}:\/\/[^\/]+[\w\d\.\-\/]*\/issues\/(\d+)[^"]*">(.+?)<\/a>)/).each do |m|
          replace_parse.sub!(m[0], '#' + m[1]) if URI.parse(m[2]).try(:host) == host && Issue.where(id: m[1]).any?
        end

        if Redmine::Plugin.installed?(:service_desk)
          orig_parse.scan(/(<a[^>]+href="http[s]{0,1}:\/\/[^\/]+[\w\d\.\-\/]*\/sd_requests\/(\d+)[^"]*">(.+?)<\/a>)/).each do |m|
            replace_parse.sub!(m[0], '#' + Setting.plugin_service_desk['num_prefix'].to_s + m[1]) if URI.parse(m[2]).try(:host) == host && SdRequest.where(id: m[1]).any?
          end
        end
      end
      replace_parse
    end
  end
end


