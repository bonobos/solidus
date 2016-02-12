require 'spec_helper'

describe Spree::Core::Permalinks do
  describe "before_validation callbacks" do
    let(:existing_permalink) { "ABCDEFG" }
    let!(:existing_shipment) { create(:shipment, number: existing_permalink) }

    let(:new_permalink)  { "123456789" }
    let(:new_shipment) { build(:shipment) }

    subject { new_shipment.save!; new_shipment}

    context "generate_permalink returns an existing permalink" do
      it "regenerates the permalink and saves to the model" do
        expect(new_shipment).to receive(:generate_permalink).and_return(existing_permalink)
        expect(new_shipment).to receive(:generate_permalink).and_return(new_permalink)

        subject
        expect(subject.number).to eq(new_permalink)
      end
    end

    context "generate_permalink returns a non-existing permalink" do
      it "permalink is not nil" do
        expect(subject.number).to_not be_nil
      end
    end
  end
end
