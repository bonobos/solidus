module Spree
  module UserAddressBook
    extend ActiveSupport::Concern

    included do
      has_many :user_addresses, foreign_key: "user_id", class_name: "Spree::UserAddress"
      has_many :addresses, through: :user_addresses

      has_one :default_user_address, -> { where default: true}, foreign_key: "user_id", class_name: 'Spree::UserAddress'
      has_one :default_address, through: :default_user_address, source: :address

      # bill_address is only minimally used now, but we can't get rid of it without a major version release
      belongs_to :bill_address, class_name: 'Spree::Address'

      def default_address
        super || Address.new(country: Country.default)
      end

      def ship_address
        #ActiveSupport::Deprecation.warn("User.ship_address is deprecated. Use #default_address instead.", caller)
        default_address
      end

      def ship_address=(address)
        #ActiveSupport::Deprecation.warn("User.ship_address= is deprecated. Use #save_in_address_book instead.", caller)
        # Deprecating this is premature because tests all over use it to create a test User.
        # #save_in_address_book doesn't play well with FactoryGirl
        # TODO default = true for now to preserve existing behavior until MyAccount UI created
        save_in_address_book(address, true)
      end

      # see "Nested Attributes Examples" section of http://apidock.com/rails/ActionView/Helpers/FormHelper/fields_for
      # this #{fieldname}_attributes= method works with fields_for in the views
      # even without declaring accepts_nested_attributes_for
      def ship_address_attributes=(attributes)
        self.ship_address = Address.new(attributes)
      end

      def bill_address=(address)
        # stow a copy in our address book too
        address = save_in_address_book(address)
        super(address)
      end

      def bill_address_attributes=(attributes)
        # preserve immutability of Address
        self.bill_address = Address.new(Address.copy_attributes(bill_address, attributes))
      end

      def persist_order_address(order)
        #TODO the 'true' there needs to change once we have MyAccount UI
        save_in_address_book(order.ship_address, true) if order.ship_address
        save_in_address_book(order.bill_address, order.ship_address.nil?) if order.bill_address
      end

      # we should take address_attributes to be clearer it's not a db row we're talking about, but address field values
      def save_in_address_book(address, default = false)
        user_address = find_user_address_by_address(address)
        return user_address.address if user_address && (!default || user_address.default == default)

        first_one = user_addresses.empty?
        user_address ||= user_addresses.build(address: address)
        mark_default_user_address(user_address) if default || first_one

        user_address.save! unless new_record?
        user_address.address
      end

      def mark_default_address(address)
        mark_default_user_address(find_user_address_by_address(address))
      end

      private

      def mark_default_user_address(user_address)
        (user_addresses - [user_address]).each {|a| a.update!(default: false)} #update_all would be nice, but it bypasses ActiveRecord callbacks
        user_address.default = true
      end

      def find_user_address_by_address(address)
        # find by value, not id
        user_addresses.joins(:address).readonly(false).where(
          spree_addresses: address.attributes.except(*Address::EQUALITY_IRRELEVANT_ATTRS)
        ).first
      end
    end
  end
end
