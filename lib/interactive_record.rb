require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash
    sql = "PRAGMA table_info('#{self.table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each{|hash|
      column_names << hash["name"]}
    column_names
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if{|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each{|col_name| values << "'#{send(col_name)}'" unless send(col_name) == nil}
    values.join(", ")
  end

  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
    VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE name = ?
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(hash)
    # binding.pry
    col_name = hash.keys[0].to_s
    if hash.values.is_a? Numeric
      value = hash.values
    else
      value = hash.values.map{ |e| "'" + e + "'" }[0]
    end
    sql = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE #{col_name} = #{value}
    SQL
    binding.pry
    DB[:conn].execute(sql)
  end
end
