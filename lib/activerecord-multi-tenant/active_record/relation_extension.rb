require_relative 'relation/spawn_method_extension'

module ActiveRecord
  # = Active Record Relation
  class Relation

    attr_accessor :creating_tenant, :multi_tenant_disabled

    alias :multi_tenant_orig_initialize :initialize
    def initialize(*args)
      # multi_tenant_orig_initialize(*args, &block)
      multi_tenant_orig_initialize(*args.first)
      @creating_tenant = MultiTenant.current_tenant_id
      @multi_tenant_disabled = MultiTenant.multi_tenant_disabled?
    end

    def multi_tenant_disabled?
      if !@multi_tenant_disabled.nil? && @multi_tenant_disabled != MultiTenant.multi_tenant_disabled? && klass.try(:scoped_by_tenant?)
        MultiTenant.warn_attribute_change(self, :multi_tenant_disabled, MultiTenant.multi_tenant_disabled?, @multi_tenant_disabled)
      end
      @multi_tenant_disabled.nil? ? MultiTenant.multi_tenant_disabled? : @multi_tenant_disabled
    end

    def get_effective_tenant_id
      cur_tenant_id = MultiTenant.current_tenant_id
      current_tenant_id, @creating_tenant = cur_tenant_id, cur_tenant_id
      current_tenant_id, @creating_tenant = 0, 0 if public_tenant?

      attr_changed_check = @creating_tenant &&
          (@creating_tenant != MultiTenant.current_tenant_id) &&
          klass.try(:scoped_by_tenant?)

      if attr_changed_check
        MultiTenant.warn_attribute_change(self, :creating_tenant,
                                          MultiTenant.current_tenant_id,
                                          @creating_tenant)
      end
      Rails.logger.info("get_effective_tenant_id ->: #{current_tenant_id}")
      current_tenant_id
    end

    # TODO: fix me later, once multi tenant issue resolved at has_one association level.
    def public_tenant?
      [0, '0', 'public', 'public_tenant'].include?(@creating_tenant)
    end
  end
end