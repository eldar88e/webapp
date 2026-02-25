class WebPushNoticeJob < ApplicationJob
  queue_as :default

  def perform(title:, body:, user_ids: nil)
    admin_tg_ids = Setting.fetch_value(:admin_ids).to_s.split(',')
    users = user_ids ? User.where(id: user_ids) : User.where(tg_id: admin_tg_ids)

    users.includes(:push_subscriptions).find_each do |user|
      user.push_subscriptions.each do |sub|
        WebPush.payload_send(
          message: { title: title, body: body }.to_json,
          endpoint: sub.endpoint,
          p256dh: sub.p256dh,
          auth: sub.auth,
          vapid: {
            public_key: ENV['VAPID_PUBLIC_KEY'],
            private_key: ENV['VAPID_PRIVATE_KEY'],
            subject: "mailto:#{ENV.fetch('EMAIL_FROM', 'noreply@example.com')}"
          }
        )
      rescue WebPush::ExpiredSubscription
        sub.destroy
      end
    end
  end
end
