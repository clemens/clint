# encoding: utf-8
$:.unshift(File.expand_path(File.dirname(__FILE__))); $:.uniq!

require 'rubygems'
require 'test_helper'

class ClintTest < Test::Unit::TestCase
  test ".trigger creates a new trigger in the database" do
    number_of_triggers = Clint.triggers.size
    Clint.trigger(:model => 'Product', :before => [:insert, :update], :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal number_of_triggers + 2, Clint.triggers.size
  end

  test ".triggers lists all currently installed triggers" do
    triggers = Clint.triggers

    assert_equal 1, triggers.size
    all_triggers_are_clint_triggers = triggers.all? { |trigger| trigger.class.name == 'Clint::Trigger' }
    assert all_triggers_are_clint_triggers
  end

  test ".build_triggers builds triggers" do
    triggers = Clint.build_triggers(:model => 'Product', :before => [:insert, :update], :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal 2, triggers.size
    all_triggers_are_clint_triggers = triggers.all? { |trigger| trigger.class.name == 'Clint::Trigger' }
    assert all_triggers_are_clint_triggers
  end

  test ".build_triggers builds a trigger with a prefix" do
    Clint.prefix = 'clint'
    trigger = Clint.build_triggers(:model => 'Product', :before => :insert, :implementation => 'SET NEW.updated_at = NOW();').first
    assert_equal 'clint_products_before_insert', trigger.name
  end

  test ".action_names generates action names" do
    action_names = Clint.action_names(:after => [:insert, :update], :before => [:delete, :insert])
    all_triggers_are_turned_into_action_names = %w(after_insert after_update before_delete before_insert).all? do |action_name|
      action_names.include?(action_name)
    end
    assert all_triggers_are_turned_into_action_names
  end

  test ".flush removes all triggers" do
    Clint.flush
    assert_equal 0, Clint.triggers.size
  end

  # load from file
  test ".load_from loads all triggers defined in a given file" do
    number_of_triggers = Clint.triggers.size
    Clint.load_from(File.dirname(__FILE__) + '/fixtures/triggers.rb')
    assert_equal number_of_triggers + 5, Clint.triggers.size
  end

  # prefix
  test ".triggers lists only triggers with prefix if prefix set" do
    Clint.prefix = 'clint'
    Clint.connection.execute <<-sql
      CREATE TRIGGER clint_carts_before_insert
      BEFORE INSERT ON items
      FOR EACH ROW
      BEGIN
        SET NEW.updated_at = NOW();
      END
    sql

    triggers = Clint.triggers
    assert_equal 1, triggers.size
    assert_equal 'clint_carts_before_insert', triggers.first.name
  end

  test ".flush removes only triggers with prefix if prefix set" do
    Clint.prefix = 'clint'
    Clint.connection.execute <<-sql
      CREATE TRIGGER clint_carts_before_insert
      BEFORE INSERT ON items
      FOR EACH ROW
      BEGIN
        SET NEW.updated_at = NOW();
      END
    sql

    Clint.flush
    # TODO maybe a slightly higher level assertion?
    assert_equal 1, Clint.connection.select_all("SHOW TRIGGERS;").size
  end
end
