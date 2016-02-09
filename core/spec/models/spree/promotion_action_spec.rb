require 'spec_helper'

module Spree
  describe Spree::PromotionAction, type: :model do

    class TestAction < Spree::PromotionAction
    end

    class TestAction::FreeShipping < Spree::PromotionAction
      include Spree::CalculatedAdjustments
    end

    class TestShippingCalculator < Calculator
      preference :amount, :decimal, default: 0
    end

    describe "#duplicate" do
      let(:promotion) { create(:promotion) }

      context "without calculator" do
        it "duplicates itself" do
          action = TestAction.new(promotion_id: promotion.id)
          new_action = action.duplicate

          expect(new_action).to_not eq action
          expect(new_action.type).to eq action.type
          expect(new_action).to be_valid
        end
      end

      context "subclass has a calculator" do
        it "duplicates itself with the calculator" do
          action  = TestAction::FreeShipping.new(promotion_id: promotion.id, calculator: TestShippingCalculator.new(preferred_amount: 5))
          new_action = action.duplicate

          expect(new_action).to_not eq action
          expect(new_action.type).to eq action.type
          expect(new_action.calculator.type).to eq action.calculator.type
          expect(new_action.calculator.preferences).to eq action.calculator.preferences
          expect(new_action).to be_valid
        end
      end
    end
  end
end
