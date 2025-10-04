module Tg
  class MessageService
    class << self
      def build_tg_message(product, text, markup)
        msg = { text: text, is_incoming: false, data: { markup: markup } }
        return msg unless product.image.attached?

        tg_media = find_or_create_tg_media(product)
        msg[:data][:type] = 'image'
        tg_media.file_id ? msg[:data][:tg_file_id] = tg_media.file_id : msg[:data][:media_id] = tg_media.id
        msg
      end

      def update_file_id(message)
        return if message.data['tg_file_id'].present? || message.data['media_id'].blank?

        sleep 3
        message.data['tg_file_id'] = TgMediaFile.find_by(id: message.data['media_id'])&.file_id
        message.save
      end

      private

      def find_or_create_tg_media(product)
        file_hash = Digest::MD5.hexdigest(product.image.download)
        TgMediaFile.fetch_or_create_by_hash(
          file_hash: file_hash,
          file_type: product.image.blob.content_type,
          original_filename: product.image.blob.filename,
          attachment: product.image.blob
        )
      end
    end
  end
end
