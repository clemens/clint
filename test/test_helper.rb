# encoding: utf-8

$:.unshift File.expand_path("../lib", File.dirname(__FILE__))
$:.unshift(File.expand_path(File.dirname(__FILE__)))
$:.uniq!

require 'rubygems'
require 'active_record'
require 'test/unit'

class Product < ActiveRecord::Base
end

class Item < ActiveRecord::Base
end

class Cart < ActiveRecord::Base
end

ActiveRecord::Base.establish_connection(:adapter => 'mysql', :database => 'clint_test', :username => 'root')

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS items;")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS products;")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS carts;")

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :products do |t|
    t.string :name
    t.datetime :updated_at
  end

  create_table :items do |t|
    t.integer :cart_id
    t.integer :product_id
    t.integer :quantity
    t.datetime :updated_at
  end

  create_table :carts do |t|
    t.datetime :updated_at
  end
end

require 'clint'

class Test::Unit::TestCase
  def setup
    Clint.prefix = nil
    Clint.flush
    Clint.connection.execute <<-sql
      CREATE TRIGGER carts_before_update
      BEFORE UPDATE ON carts
      FOR EACH ROW
      BEGIN
        SET NEW.updated_at = NOW();
      END
    sql
  end

  class << self
    def test(name, &block)
      test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
      defined = instance_method(test_name) rescue false

      raise "#{test_name} is already defined in #{self}" if defined

      if block_given?
        define_method(test_name, &block)
      else
        define_method(test_name) do
          flunk "No implementation provided for #{name}"
        end
      end
    end
  end
end
