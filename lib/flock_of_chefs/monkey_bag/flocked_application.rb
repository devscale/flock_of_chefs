require 'thread'

module FlockOfChefs
  module FlockedApplication
    def mutex
      unless(@mutex)
        @mutex = Mutex.new
      end
      @mutex
    end

    def flocked_run_chef_client
      mutex.synchronize do
        original_run_chef_client
      end
    end

    class << self
      def included(base)
        base.class_eval do
          alias_method :original_run_chef_client, :run_chef_client
          alias_method :run_chef_client, :flocked_run_chef_client
        end
      end

      def extended(base)
        base.instance_eval do
          alias :original_run_chef_client :run_chef_client
          alias :run_chef_client :flocked_run_chef_client
        end
      end
    end
  end
end

# Hook into Application classes
%w(Client Solo WindowsService).each do |app|
  begin
    klass = Chef::Application.const_get(app)
    klass.send(:include, FlockOfChefs::FlockedApplication)
  rescue NameError
    # Not defined!
  end
end

# Hook into existing instances if we are loading up via
# cookbook not client.rb
ObjectSpace.each_object(Chef::Application) do |app_inst|
  unless(app_inst.respond_to?(:flocked_run_chef_client))
    app_inst.extend(FlockOfChefs::FlockedApplication)
  end
end