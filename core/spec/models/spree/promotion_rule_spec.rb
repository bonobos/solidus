require 'spec_helper'

module Spree
  describe Spree::PromotionRule, type: :model do

    class BadTestRule < Spree::PromotionRule; end

    class TestRule < Spree::PromotionRule
      def eligible?(promotable, options = {})
        true
      end
    end

    it "forces developer to implement eligible? method" do
      expect { BadTestRule.new.eligible?("promotable") }.to raise_error NotImplementedError
    end

    it "validates unique rules for a promotion" do
      p1 = TestRule.new
      p1.promotion_id = 1
      p1.save

      p2 = TestRule.new
      p2.promotion_id = 1
      expect(p2).not_to be_valid
    end

    describe "#duplicate" do
      let(:promotion) { create(:promotion) }

      context "subclass does not define a join_table" do
        it "duplicates itself" do
          rule = TestRule.new(promotion_id: promotion.id)
          new_rule = rule.duplicate

          expect(new_rule).to_not eq rule
          expect(new_rule).to be_valid
        end
      end

      context "subclass defines a join_table" do
        it "duplicates itself with the joined record" do
          product = create(:product)
          rule = Spree::Promotion::Rules::Product.new(promotion_id: promotion.id, products: [product])
          new_rule = rule.duplicate

          expect(new_rule).to_not eq rule
          expect(new_rule.products.length).to eq rule.products.length
          expect(new_rule.products.length).to eq 1
          expect(new_rule.products.first).to eq product
          expect(new_rule).to be_valid
        end
      end
    end
  end
end
