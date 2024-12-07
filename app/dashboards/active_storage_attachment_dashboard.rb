require "administrate/base_dashboard"

class ActiveStorageAttachmentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    record: Field::Polymorphic,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    record
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    record
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    record
  ].freeze
end
