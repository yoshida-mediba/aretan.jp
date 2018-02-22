module Acl::Patches::Models
  module QueryPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do

        alias_method_chain :sql_for_field, :acl
        alias_method_chain :parse_date, :acl

        self.operators_by_filter_type[:acl_date_time] = %w(= >< >= <= !* *)
      end
    end

    module InstanceMethods

      def sql_for_field_with_acl(field, operator, value, db_table, db_field, is_custom_filter=false)
        if operator == '><' && type_for(field) == :acl_date_time
          sql = date_clause(db_table, db_field, parse_date(value[0]), parse_date(value[1]), is_custom_filter)
        elsif operator == '<=' && type_for(field) == :acl_date_time
          sql = date_clause(db_table, db_field, nil, parse_date(value.first), is_custom_filter)
        elsif operator == '>=' && type_for(field) == :acl_date_time
          sql = date_clause(db_table, db_field, parse_date(value.first), nil, is_custom_filter)
        else
          sql = sql_for_field_without_acl(field, operator, value, db_table, db_field, is_custom_filter)
        end
        sql
      end

      def parse_date_with_acl(arg)
        if arg.to_s =~ /\A\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}/
          User.current.acl_user_to_server_time(arg.to_s, true)
        else
          parse_date_without_acl(arg)
        end
      end
    end

  end
end