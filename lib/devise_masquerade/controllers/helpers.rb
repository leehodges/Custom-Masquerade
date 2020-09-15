module DeviseMasquerade
  module Controllers
    module Helpers
      def self.define_helpers(mapping)
        name = mapping.name
        class_name = mapping.class_name

        class_eval <<-METHODS, __FILE__, __LINE__ + 1
          def masquerade_#{name}!
            return if params["#{Devise.masquerade_param}"].blank?

            #{name} = ::#{class_name}.find_by_masquerade_key(params["#{Devise.masquerade_param}"])

            if #{name}
              masquerade_sign_in(#{name})
            end
          end

          def #{name}_masquerade?
            session[:"devise_masquerade_#{name}"].present?
          end

          def #{name}_masquerade_owner
            return nil unless send(:#{name}_masquerade?)
            ::#{class_name}.to_adapter.find_first(:id => session[:"devise_masquerade_#{name}"])
          end

          private

          def masquerade_sign_in(resource)
            if Devise.masquerade_bypass_warden_callback
              if respond_to?(:bypass_sign_in)
                bypass_sign_in(resource)
              else
                sign_in(resource, :bypass => true)
              end
            else
              sign_in(resource)
            end
          end
        METHODS

        ActiveSupport.on_load(:action_controller) do
          if respond_to?(:helper_method)
            helper_method "#{name}_masquerade?"
            helper_method "#{name}_masquerade_owner"
          end
        end
      end
    end
  end
end

ActionController::Base.send(:include, DeviseMasquerade::Controllers::Helpers)
