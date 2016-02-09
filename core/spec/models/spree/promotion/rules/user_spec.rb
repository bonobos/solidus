require 'spec_helper'

describe Spree::Promotion::Rules::User, :type => :model do
  let(:rule) { Spree::Promotion::Rules::User.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "should not be eligible if users are not provided" do
      expect(rule).not_to be_eligible(order)
    end

    it "should be eligible if users include user placing the order" do
      user = mock_model(Spree::LegacyUser)
      users = [user, mock_model(Spree::LegacyUser)]
      allow(rule).to receive_messages(:users => users)
      allow(order).to receive_messages(:user => user)

      expect(rule).to be_eligible(order)
    end

    it "should not be eligible if user placing the order is not listed" do
      allow(order).to receive_messages(:user => mock_model(Spree::LegacyUser))
      users = [mock_model(Spree::LegacyUser), mock_model(Spree::LegacyUser)]
      allow(rule).to receive_messages(:users => users)

      expect(rule).not_to be_eligible(order)
    end

    # Regression test for #3885
    it "can assign to user_ids" do
      user1 = Spree::LegacyUser.create!(:email => "test1@example.com")
      user2 = Spree::LegacyUser.create!(:email => "test2@example.com")
      expect { rule.user_ids = "#{user1.id}, #{user2.id}" }.not_to raise_error
    end
  end

  describe "#duplicate" do
    let(:duplicated) { rule.duplicate }

    context "with users" do
      let(:user1) { mock_model(Spree::LegacyUser)}
      let(:user2) { mock_model(Spree::LegacyUser)}
      before { rule.users = [user1, user2] }

      it "creates duplicate" do
        expect(duplicated.preferences).to eq(rule.preferences)
        expect(duplicated.promotion_rule_users.length).to eq 2
        expect(duplicated.promotion_rule_users.map(&:user_id)).to eq([user1.id, user2.id])
        expect(duplicated.users).to eq rule.users
      end
    end

    context "without users" do
      it "creates duplicate" do
        expect(duplicated.preferences).to eq(rule.preferences)
        expect(duplicated.promotion_rule_users).to be_empty
      end
    end
  end
end
