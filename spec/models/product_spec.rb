# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to have_many(:product_subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:subscribers).through(:product_subscriptions).source(:user) }
    it { is_expected.to have_one_attached(:image) }
  end

  describe 'validations' do
    subject { build(:product) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:stock_quantity).is_greater_than_or_equal_to(0) }

    describe '#acceptable_image' do
      let(:product) { build(:product) }

      context 'when no image is attached' do
        it 'does not add errors' do
          product.image.detach if product.image.attached?
          product.valid?
          expect(product.errors[:image]).to be_empty
        end
      end

      context 'when the attached image is larger than 1MB' do
        it 'adds an error about file size' do
          fake_image = double('attached_image',
                              attached?: true,
                              byte_size: 1.megabyte + 1,
                              content_type: 'image/png')
          allow(product).to receive(:image).and_return(fake_image)
          product.valid?
          expect(product.errors[:image]).to include('должно быть меньше 1 МБ')
        end
      end

      context 'when the attached image has an invalid format' do
        it 'adds an error about file format' do
          fake_image = double('attached_image',
                              attached?: true,
                              byte_size: 500.kilobytes,
                              content_type: 'application/pdf')
          allow(product).to receive(:image).and_return(fake_image)
          product.valid?
          expect(product.errors[:image]).to include('должно быть JPEG или PNG или WEBP')
        end
      end

      context 'when the attached image is valid' do
        it 'does not add errors' do
          fake_image = double('attached_image',
                              attached?: true,
                              byte_size: 500.kilobytes,
                              content_type: 'image/jpeg')
          allow(product).to receive(:image).and_return(fake_image)
          product.valid?
          expect(product.errors[:image]).to be_empty
        end
      end
    end
  end

  describe 'scopes' do
    let!(:available_product) { create(:product, deleted_at: nil) }
    let!(:deleted_product)   { create(:product, deleted_at: Time.current) }
    let!(:child_product)     { create(:product, ancestry: '1') }

    describe '.available' do
      it 'returns products with deleted_at set to nil' do
        expect(Product.available).to include(available_product)
        expect(Product.available).not_to include(deleted_product)
      end
    end

    describe '.deleted' do
      it 'returns products with deleted_at not nil' do
        expect(Product.deleted).to include(deleted_product)
        expect(Product.deleted).not_to include(available_product)
      end
    end

    describe '.children_only' do
      it 'returns products with ancestry set' do
        expect(Product.children_only).to include(child_product)
        expect(Product.children_only).not_to include(available_product)
      end
    end
  end

  describe 'callbacks' do
    before do
      allow(Setting).to receive(:fetch_value).with(:admin_ids).and_return('admin_id')
      allow(Setting).to receive(:fetch_value).with(:root_product_id).and_return('root_product_id')
    end

    describe 'normalize_ancestry' do
      it 'converts empty string to nil' do
        product = build(:product, ancestry: '')
        product.validate
        expect(product.ancestry).to be_nil
      end
    end
  end

  describe 'instance methods' do
    describe '#destroy' do
      it 'soft deletes the product and its descendants by setting deleted_at' do
        parent = create(:product)
        child  = create(:product, ancestry: parent.id.to_s)
        parent.destroy
        parent.reload
        child.reload
        expect(parent.deleted_at).not_to be_nil
        expect(child.deleted_at).not_to be_nil
      end
    end

    describe '#restore' do
      it 'restores a soft-deleted product by setting deleted_at to nil' do
        product = create(:product, deleted_at: Time.current)
        product.restore
        expect(product.deleted_at).to be_nil
      end
    end

    describe '#deleted?' do
      it 'returns true if the product is soft-deleted' do
        product = create(:product, deleted_at: Time.current)
        expect(product.deleted?).to be_truthy
      end

      it 'returns false if the product is not deleted' do
        product = create(:product, deleted_at: nil)
        expect(product.deleted?).to be_falsey
      end
    end

    describe '#subscribed?' do
      let(:user)    { create(:user) }
      let(:product) { create(:product) }

      it 'returns true, if user subscribed to product' do
        create(:product_subscription, product: product, user: user)
        expect(product.subscribed?(user)).to be_truthy
      end

      it 'returns false, if user not subscribed to product' do
        expect(product.subscribed?(user)).to be_falsey
      end
    end
  end
end
