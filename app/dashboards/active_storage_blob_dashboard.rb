require "administrate/base_dashboard"

class ActiveStorageBlobDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    key: Field::String,
    filename: Field::String,
    content_type: Field::String,
    metadata: Field::Text,
    byte_size: Field::Number,
    checksum: Field::String,
    created_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    filename
    content_type
    byte_size
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    key
    filename
    content_type
    metadata
    byte_size
    checksum
    created_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    key
    filename
    content_type
    metadata
  ].freeze
end
