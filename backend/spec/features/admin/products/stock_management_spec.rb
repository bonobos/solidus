require 'spec_helper'

describe "Stock Management", :type => :feature do
  stub_authorization!

  before(:each) do
    visit spree.admin_path
  end

  context "given a product with a variant and a stock location" do
    let!(:stock_location) { create(:stock_location, name: 'Default') }
    let!(:product) { create(:product, name: 'apache baseball cap', price: 10) }
    let!(:variant) { create(:variant, product: product) }
    let(:stock_item) { variant.stock_items.find_by(stock_location: stock_location) }

    before do
      stock_location.stock_item(variant).update_column(:count_on_hand, 10)

      click_link "Products"
      within_row(1) { click_icon :edit }
      click_link "Stock Management"
    end

    # Regression test for #3304
    # It is OK to still render the stock page, ensure no errors in this case
    context "with no stock location" do
      before do
        @product = create(:product, name: 'apache baseball cap', price: 10)
        v = @product.variants.create!(sku: 'FOOBAR')
        Spree::StockLocation.destroy_all
        click_link "Products"
        within_row(1) do
          click_icon :edit
        end
        click_link "Stock Management"
      end

      it "renders" do
        expect(page).to have_content(Spree.t(:editing_product))
        expect(page.current_url).to match("admin/products/apache-baseball-cap/stock")
      end
    end

    it "can create a positive stock adjustment", js: true do
      adjust_count_on_hand('14')
      stock_item.reload
      expect(stock_item.count_on_hand).to eq 14
      expect(stock_item.stock_movements.count).to eq 1
      expect(stock_item.stock_movements.first.quantity).to eq 4
    end

    it "can create a negative stock adjustment", js: true do
      adjust_count_on_hand('4')
      stock_item.reload
      expect(stock_item.count_on_hand).to eq 4
      expect(stock_item.stock_movements.count).to eq 1
      expect(stock_item.stock_movements.first.quantity).to eq -6
    end

    def adjust_count_on_hand(count_on_hand)
      find(:css, ".fa-edit[data-id='#{stock_item.id}']").click
      find(:css, "[data-variant-id='#{variant.id}'] input[type='number']").set(count_on_hand)
      find(:css, ".fa-check[data-id='#{stock_item.id}']").click
      expect(page).to have_content('Updated successfully')
    end

    context "with multiple stock locations" do
      before do
        create(:stock_location, name: 'Other location', propagate_all_variants: false)
      end

      it "can add stock items to other stock locations", js: true do
        visit current_url
        fill_in "variant-count-on-hand-#{variant.id}", with: '3'
        targetted_select2_search "Other location", from: "#s2id_variant-stock-location-#{variant.id}"
        find(:css, ".fa-plus[data-variant-id='#{variant.id}']").click
        wait_for_ajax
        expect(page).to have_content('Created successfully')
      end
    end
  end
end
