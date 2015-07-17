module Spree
  class Address < Spree::Base
    require 'twitter_cldr'

    belongs_to :country, class_name: "Spree::Country"
    belongs_to :state, class_name: "Spree::State"

    has_many :shipments, inverse_of: :address
    has_many :cartons, inverse_of: :address
    has_many :credit_cards, inverse_of: :address

    validates :firstname, :lastname, :address1, :city, :country_id, presence: true
    validates :zipcode, presence: true, if: :require_zipcode?
    validates :phone, presence: true, if: :require_phone?

    validate :state_validate, :postal_code_validate

    alias_attribute :first_name, :firstname
    alias_attribute :last_name, :lastname

    UNCOPIED_ATTRS = ['id', 'updated_at']
    EQUALITY_IRRELEVANT_ATTRS = ['id', 'updated_at', 'created_at']

    def self.build_default
      new(country: Spree::Country.default)
    end

    def self.default(user = nil, kind = "bill")
      ActiveSupport::Deprecation.warn("Address.default is deprecated. You should either use Country.default explicitly, or User.default_address", caller)
      if user
        user.send(:"#{kind}_address") || build_default
      else
        build_default
      end
    end

    def self.copy_attributes(existing_address, new_attributes)
      existing_attrs = existing_address.try(:attributes) || {}
      existing_attrs.merge(new_attributes).with_indifferent_access.except(*UNCOPIED_ATTRS)
    end

    def full_name
      "#{firstname} #{lastname}".strip
    end

    # @return [String] a string representation of this state
    def state_text
      state.try(:abbr) || state.try(:name) || state_name
    end

    def to_s
      "#{full_name}: #{address1}"
    end

    def ==(other_address)
      self_attrs = self.attributes.except(*EQUALITY_IRRELEVANT_ATTRS)
      other_attrs = (other_address.try(:attributes) || {}).except(*EQUALITY_IRRELEVANT_ATTRS)

      self_attrs == other_attrs
    end

    def same_as?(other_address)
      ActiveSupport::Deprecation.warn("Address.same_as? is deprecated. It's equivalent to Address.==", caller)
      self == other_address
    end

    def same_as(other_address)
      ActiveSupport::Deprecation.warn("Address.same_as is deprecated. It's equivalent to Address.==", caller)
      self == other_address
    end

    def empty?
      attributes.except('id', 'created_at', 'updated_at', 'country_id').all? { |_, v| v.nil? }
    end

    # @return [Hash] an ActiveMerchant compatible address hash
    def active_merchant_hash
      {
        name: full_name,
        address1: address1,
        address2: address2,
        city: city,
        state: state_text,
        zip: zipcode,
        country: country.try(:iso),
        phone: phone
      }
    end

    # @todo Remove this from the public API if possible.
    # @return [true] whether or not the address requires a phone number to be
    #   valid
    def require_phone?
      true
    end

    # @todo Remove this from the public API if possible.
    # @return [true] whether or not the address requires a zipcode to be valid
    def require_zipcode?
      true
    end

    # This is set in order to preserve immutability of Addresses. Use #dup to create
    # new records as required, but it probably won't be required as often as you think.
    # Since addresses do not change, you won't accidentally alter historical data.
    def readonly?
      persisted?
    end

    private
      def state_validate
        # Skip state validation without country (also required)
        # or when disabled by preference
        return if country.blank? || !Spree::Config[:address_requires_state]
        return unless country.states_required

        # ensure associated state belongs to country
        if state.present?
          if state.country == country
            self.state_name = nil #not required as we have a valid state and country combo
          else
            if state_name.present?
              self.state = nil
            else
              errors.add(:state, :invalid)
            end
          end
        end

        # ensure state_name belongs to country without states, or that it matches a predefined state name/abbr
        if state_name.present?
          if country.states.present?
            states = country.states.find_all_by_name_or_abbr(state_name)

            if states.size == 1
              self.state = states.first
              self.state_name = nil
            else
              errors.add(:state, :invalid)
            end
          end
        end

        # ensure at least one state field is populated
        errors.add :state, :blank if state.blank? && state_name.blank?
      end

      def postal_code_validate
        return if country.blank? || country.iso.blank? || !require_zipcode?
        return if !TwitterCldr::Shared::PostalCodes.territories.include?(country.iso.downcase.to_sym)

        postal_code = TwitterCldr::Shared::PostalCodes.for_territory(country.iso)
        errors.add(:zipcode, :invalid) if !postal_code.valid?(zipcode.to_s)
      end
  end
end
