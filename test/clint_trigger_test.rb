# encoding: utf-8
$:.unshift(File.expand_path(File.dirname(__FILE__))); $:.uniq!

require 'test_helper'

class ClintTriggerTest < Test::Unit::TestCase
  def setup
    super
    @trigger = Clint::Trigger.new(:model => 'Product', :action => 'before_insert', :implementation => 'SET NEW.updated_at = NOW();')
  end

  test "#name generates a name from the model name and action" do
    assert_equal 'products_before_insert', @trigger.name
  end

  test "#name generates name from table name and action" do
    trigger = Clint::Trigger.new(:table_name => 'products', :action => 'before_insert', :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal 'products_before_insert', trigger.name
  end

  test "#name uses a given name" do
    trigger = Clint::Trigger.new(:name => 'products_before_insert', :table_name => 'products', :action => 'before_insert', :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal 'products_before_insert', trigger.name
  end

  test "#name uses a given name even if table name, model and action are given" do
    trigger = Clint::Trigger.new(:name => 'trigger_products_before_insert', :table_name => 'products', :model => 'Item', :action => 'before_insert', :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal 'trigger_products_before_insert', trigger.name
  end

  test "#table_name queries the table name from the given model" do
    assert_equal 'products', @trigger.table_name
  end

  test "#table_name uses a given table name" do
    trigger = Clint::Trigger.new(:table_name => 'products', :action => 'before_insert', :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal 'products', trigger.table_name
  end

  test "#table_name uses a given table name even if model is given" do
    trigger = Clint::Trigger.new(:model => 'Item', :table_name => 'products', :action => 'before_insert', :implementation => 'SET NEW.updated_at = NOW();')
    assert_equal 'products', trigger.table_name
  end
  
  test "#install installs the trigger in the database" do
    assert_nothing_raised { @trigger.install }
  end

  test "#remove removes the trigger from the database" do
    assert_nothing_raised { @trigger.remove }
  end

  test "#replace replaces the trigger in the database if it exists" do
    assert_nothing_raised { @trigger.replace }
  end

  # FIXME how to best test this?
  # test "#to_sql generates the trigger's SQL"
  # test "#drop_trigger_sql generates the trigger's drop SQL"
end
