class AddReportDate < ActiveRecord::Migration
  def self.up
    add_column :blogs, :report_date, :date
    add_index :blogs, :report_date
  end

  def self.down; end
end
