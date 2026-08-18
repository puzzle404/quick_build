require "rails_helper"

RSpec.describe MaterialListPublication, type: :model do
  subject(:publication) { build(:material_list_publication) }

  it { is_expected.to belong_to(:material_list) }

  describe "#publish!" do
    it "marca la publicación como pública" do
      publication = described_class.create!(material_list: create(:material_list))

      publication.publish!

      expect(publication).to be_visibility_public
      expect(publication.published_at).to be_present
      expect(publication.unpublished_at).to be_nil
    end
  end

  describe "#unpublish!" do
    it "marca la publicación como privada" do
      publication = described_class.create!(material_list: create(:material_list), visibility: :public)

      publication.unpublish!

      expect(publication).to be_visibility_private
      expect(publication.unpublished_at).to be_present
    end
  end
end
