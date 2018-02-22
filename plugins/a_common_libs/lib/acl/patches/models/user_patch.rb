module Acl::Patches::Models
  module UserPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def favourite_project
        @fv_pr ||= (Project.where(id: self.preference.try(:favourite_project_id).to_i).first || get_favourite_project)
      end

      def get_favourite_project
        return @fav_project if @fav_project
        @fav_project = Project.select("#{Project.table_name}.*, COUNT(#{Journal.table_name}.id) AS num_actions")
                              .joins({ issues: :journals })
                              .where("#{Journal.table_name}.user_id = ?", id)
                              .group("projects.#{Project.column_names.join(', projects.')}")
                              .order('num_actions DESC')
                              .limit(1)
                              .try(:first)

        @fav_project = Project.all.first unless @fav_project

        if self.preference.try(:favourite_project_id).nil? && !@fav_project.nil?
          self.preference = self.build_preference if self.preference.blank?
          self.preference.favourite_project_id = @fav_project.id
          self.preference.save
        end

        @fav_project
      end

      def acl_user_to_server_time(time, ignore_zone=false)
        return nil if time.blank?
        zone = self.time_zone

        if time.is_a?(Time) && ignore_zone
          time = time.strftime('%Y-%m-%d %H:%M:%S')
        end

        if time.is_a?(String)
          if zone.blank?
            if self.class.default_timezone == :utc
              tm = ActiveSupport::TimeZone[Time.now.utc.zone].parse(time)
            else
              tm = Time.parse(time)
            end
          else
            tm = zone.parse(time)
          end
        else
          tm = time
        end

        if tm
          if self.class.default_timezone == :utc
            tm = tm.utc
          elsif self.class.default_timezone == :local
            tm = tm.localtime
          end
        end

        tm
      end

      def acl_server_to_user_time(time)
        return nil unless time
        if time.is_a?(String)
          if self.class.default_timezone == :utc
            time = time.strip + ' UTC'
          end
          tm = Time.parse(time) rescue nil
          return nil unless tm
        else
          tm = time
        end
        zone = User.current.time_zone
        zone ? tm.in_time_zone(zone) : tm
      end

      def acl_not_served_log_count(view_context=nil, params=nil, session=nil)
        ApiLogForPlugin.where(served: false).size
      end
    end

  end
end
