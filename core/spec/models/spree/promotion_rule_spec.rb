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
      let(:promotion) { Spree::Promotion.last || create(:promotion) }

      context "subclass does not define a join_table" do
        it "duplicates itself" do
          rule = TestRule.new(promotion_id: promotion.id)
          new_rule = rule.duplicate

          expect(new_rule).to_not eq rule
          expect(new_rule).to be_valid
        end
      end

      context "subclass defines a join_table" do

        class TestRule::Product < Spree::PromotionRule
          attr_accessor :test_rule_test_products
          self.association_for_duplication = "test_rule_test_products"
        end

        class TestProduct
          attr_accessor :promotion_rule_id

          def initialize(id)
            @promotion_rule_id = id
          end
        end

        it "duplicates itself with the joined record" do
          rule = TestRule::Product.new(promotion_id: promotion.id, test_rule_test_products: [TestProduct.new(1)])
          new_rule = rule.duplicate

          expect(new_rule).to_not eq rule
          expect(new_rule.test_rule_test_products.length).to eq rule.test_rule_test_products.length
          expect(new_rule).to be_valid
        end
      end
    end
  end
end
