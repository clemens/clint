require 'active_support'

class Clint
  EVENTS = [:insert, :update, :delete]
  TIMES  = [:before, :after]

  class Trigger
    def initialize(options = {})
      raise ArgumentError.new('You must specify :action') unless options[:action]
      raise ArgumentError.new('You must specify :implementation') unless options[:implementation]
      raise ArgumentError.new('You must specify :table_name or :model') unless options[:table_name] || options[:model]

      @options = options
    end

    def name
      @name = begin
        name = @options[:name] || [table_name, @options[:action]].compact.join('_')
        name = [Clint.prefix, name].join('_') if Clint.prefix && !(name[0, Clint.prefix.length] == Clint.prefix) # TODO extract
        name
      end
    end

    def table_name
      @table_name ||= @options[:table_name] || model.table_name
    end

    def action_name
      @action_name ||= @options[:action].upcase.gsub('_', ' ')
    end

    def model
      @model ||= @options[:model].constantize
    end

    def implementation
      @options[:implementation]
    end

    # FIXME this is all MySQL-specific
    def to_sql
      <<-sql
        CREATE TRIGGER #{name}
        #{action_name} ON #{table_name}
        FOR EACH ROW
        #{implementation}
      sql
    end

    def drop_trigger_sql
      <<-sql
        DROP TRIGGER IF EXISTS #{name};
      sql
    end

    def install
      Clint.connection.raw_connection.set_server_option(Mysql::OPTION_MULTI_STATEMENTS_ON) # YUCK
      Clint.connection.execute(self.to_sql)
    end

    def remove
      Clint.connection.raw_connection.set_server_option(Mysql::OPTION_MULTI_STATEMENTS_ON) # YUCK
      Clint.connection.execute(self.drop_trigger_sql)
    end

    def replace
      remove
      install
    end
  end

  cattr_accessor :connection
  self.connection = ActiveRecord::Base.connection

  cattr_accessor :prefix
  self.prefix = nil

  class << self
    def load_from(filename)
      instance_eval File.read(filename)
    end

    def flush
      triggers.each { |trigger| trigger.remove }
    end

    def trigger(options = {})
      triggers = build_triggers(options)
      triggers.each { |trigger| options[:force] ? trigger.replace : trigger.install }
    end

    def triggers
      connection.select_all("SHOW TRIGGERS;").collect do |result|
        next if Clint.prefix && !(result['Trigger'][0, Clint.prefix.length] == Clint.prefix) # TODO extract

        Clint::Trigger.new(
          :name => result['Trigger'],
          :action => [result['Timing'], result['Event']].join('_'),
          :table_name => result['Table'],
          :implementation => result['Statement']
        )
      end.compact
    end

    def build_triggers(options = {})
      action_names(options).collect do |action_name|
        Clint::Trigger.new(options.merge(:action => action_name))
      end
    end

    def action_names(actions = {})
      actions.select { |action, events| TIMES.include?(action.to_sym) }.inject([]) do |actions, (time, events)|
        Array(events).select { |event| EVENTS.include?(event.to_sym) }.each do |event|
          actions << "#{time}_#{event}"
        end
        actions
      end
    end
  end
end
