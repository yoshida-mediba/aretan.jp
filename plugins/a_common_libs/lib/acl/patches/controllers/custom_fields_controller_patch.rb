module Acl::Patches::Controllers
  module CustomFieldsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        accept_api_auth :ajax_values

        skip_before_filter :require_admin, only: [:ajax_values]
      end
    end

    module InstanceMethods

      def ajax_values
        cf = CustomField.find(params[:id])
        project = Project.where(id: params[:project_id]).first

        customized = cf.class.name.gsub('CustomField', '').safe_constantize
        if !customized.nil? && customized <= ActiveRecord::Base
          customized = customized.where(id: params[:customized_id]).first
          if customized.respond_to?(:visible?) && !customized.visible?
            render_403
            return
          end
          project = customized.project if project.blank? && customized.respond_to?(:project)
        else
          customized = nil
        end

        if project && (!project.visible? || !cf.visible_by?(project, User.current))
          render_403
          return
        end

        if cf.format.respond_to?(:possible_values_records)
          res = []
          cf.format.possible_values_records(cf, customized || project, params[:q]) { |it, id, value| res << { id: id, text: value } }
          render json: res
        else
          render json: cf.format.possible_values_options(cf, customized || project).select { |it| it[0].mb_chars.downcase.include?(params[:q].mb_chars.downcase) }.map { |it| { id: it[1], text: it[0] } }
        end
      end
    end

  end
end