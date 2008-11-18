module ActiveRecord #:nodoc:

  module Nodestroyed #:nodoc:

    def self.included(base)
      base.extend(ClassMethods)
      class << base
        alias_method :find_origin, :find
        alias_method :destroy_origin, :destroy
      end
    end

    module ClassMethods
      def self.extended(base)
        Dir.glob(RAILS_ROOT + '/app/models/**/*.rb').each { |file| require file }
        models_need_add_destroyed = Array.new
        Object.subclasses_of(ActiveRecord::Base).each do |model|
          next if model.to_s == "CGI::Session::ActiveRecordStore::Session"
          model.act_as_nodestroyed
        end
      end

      def act_as_nodestroyed
        extend(ActiveRecord::Nodestroyed::SingletonMethods)
        include(ActiveRecord::Nodestroyed::InstanceMethods)
      end
    end

    module SingletonMethods
      def nodestroyed?
        self.new.nodestroyed?
      end

      def find(*args)
        find_origin(*args) unless nodestroyed?
        options = args.extract_options!
        args << options_excluding_destroyed(options)
        # puts "===========#{args}"
        find_origin *args
      end

      def destroyed_condition(table_name)
        "#{table_name}.destroyed = 0"
      end

      def options_excluding_destroyed(options)
        # need check :join, :include
        options = Hash.new if options.nil?
        if options.has_key?(:conditions) and !options[:conditions].nil?
          case options[:conditions]
          when Array
            options[:conditions][0] = destroyed_condition(quoted_table_name)+" AND "+options[:conditions][0]
          when Hash
            options[:conditions][:destroyed] = 0
          else
            options[:conditions] = destroyed_condition(quoted_table_name)+" AND "+options[:conditions]
          end
        else
          options[:conditions] = destroyed_condition(quoted_table_name)
        end
        options
      end

    end

    module InstanceMethods
      def nodestroyed?
        self.respond_to? :destroyed
      end

      def destroy
        return self.destroy_origin unless nodestroyed?
        self.destroyed = true
        save
      end

    end

  end
end