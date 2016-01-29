require 'spec_helper'

module Spree
  module Admin
    describe VariantsController, :type => :controller do
      stub_authorization!

      describe "#index" do
        let(:product) { create(:product) }
        let!(:variant_1) { create(:variant, product: product) }
        let!(:variant_2) { create(:variant, product: product) }

        context "deleted is not requested" do
          it "assigns the variants for a requested product" do
            spree_get :index, product_id: product.slug
            expect(assigns(:collection)).to include variant_1
            expect(assigns(:collection)).to include variant_2
          end
        end

        context "deleted is requested" do
          before { variant_2.destroy }
          it "assigns only deleted variants for a requested product" do
            spree_get :index, product_id: product.slug, deleted: "on"
            expect(assigns(:collection)).not_to include variant_1
            expect(assigns(:collection)).to include variant_2
          end
        end

        context "pagination" do
          it "sets pagination with URL params when specified" do
            spree_get :index, product_id: product.slug, per_page: "1"
            expect(assigns(:collection).count).to eq 1
          end

          it "sets pagination with default configuration when per_page param is not in URL" do
            spree_get :index, product_id: product.slug
            expect(assigns(:collection).count).to eq 2
          end
        end
      end
    end
  end
end
