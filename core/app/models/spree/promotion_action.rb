module Spree
  # Base class for all types of promotion action.
  #
  # PromotionActions perform the necessary tasks when a promotion is activated
  # by an event and determined to be eligible.
  class PromotionAction < Spree::Base
    acts_as_paranoid

    belongs_to :promotion, class_name: 'Spree::Promotion'

    scope :of_type, ->(t) { where(type: t) }

    # Updates the state of the order or performs some other action depending on
    # the subclass options will contain the payload from the event that
    # activated the promotion. This will include the key :user which allows
    # user based actions to be performed in addition to actions on the order
    #
    # @note This method should be overriden in subclassses.
    def perform(options = {})
      raise 'perform should be implemented in a sub-class of PromotionAction'
    end

    def duplicate
      duplicated_action = self.dup
      duplicated_action.calculator = calculator.dup if respond_to?(:calculator)
      duplicated_action
    end
  end
end
