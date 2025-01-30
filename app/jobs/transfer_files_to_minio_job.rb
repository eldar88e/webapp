# Run Example TransferFilesToMinioJob.perform_now(klass: 'Product', column: :image, limit: 2000)

class TransferFilesToMinioJob < ApplicationJob
  queue_as :default

  def perform(**args)
    klass = args[:klass].camelize.constantize
    items = fetch_items(klass, **args)
    count = transfer(items, klass, args[:column])
    msg   = "✅ Exported to MinIO #{count} for #{klass} attachments"
    TelegramService.call(msg)
    clean if count.positive?
  end

  private

  def clean
    unattached_blobs = ActiveStorage::Blob.unattached
    unattached_blobs.each(&:purge)
    msg = "⚠️ Cleared #{unattached_blobs.size} unattached blobs and images."
    TelegramService.call(msg) if unattached_blobs.size.positive?
  end

  def fetch_items(klass, **args)
    column       = args[:column]
    limit        = args[:limit]
    service_name = args[:service_name] || 'local'
    klass.includes("#{column}_attachment" => :blob)
         .where(active_storage_blobs: { service_name: service_name })
         .limit(limit)
  end

  def transfer(items, klass, column)
    count = 0
    items.find_each do |item| # get default 1000 items
      next unless item.send(column).attached?

      local_file = item.send(column).download
      save_attachment(item, local_file, column)
      count += 1
    rescue StandardError => e
      Rails.logger.error "Failed to transfer file for #{klass}: #{item.id}: #{e.message}"
    end
    count
  end

  def save_attachment(item, local_file, column)
    item.send(column).attach(
      io: StringIO.new(local_file),
      filename: item.send(column).filename.to_s,
      content_type: item.send(column).content_type
    )
  end
end
