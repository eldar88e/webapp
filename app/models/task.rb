class Task < ApplicationRecord
  ADMIN_ID = 12

  has_rich_text :description

  has_many_attached :images
  has_many_attached :files

  has_many :comments, dependent: :destroy

  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :user

  enum :stage, { idea: 0, approved: 1, in_progress: 2, reviewing: 3, done: 4 }
  enum :priority, { lowest: 0, low: 1, medium: 2, high: 3 }
  enum :category, { design: 0, dev: 1, marketing: 2 }
  enum :task_type, { sprint: 0, bugfix: 1, feature: 2 }

  validates :title, presence: true

  after_commit :send_create_to_telegram, on: :create
  after_commit :send_update_to_telegram, on: :update

  private

  def send_create_to_telegram
    send_to_telegram(true)
  end

  def send_update_to_telegram
    send_to_telegram
  end

  def send_to_telegram(create = nil)
    msg = create ? "📋 Новая задача: #{title}" : "📋 Задача ’’#{title}’’ обновлена"
    msg += "\n\nСтатус: #{I18n.t("stage.#{stage}")}"
    assignee.messages.create(text: msg, is_incoming: false)
    send_to_admin(msg) if assignee.id != ADMIN_ID && %w[approved reviewing done].include?(stage)
    user.messages.create(text: msg, is_incoming: false) if assignee.id != user.id
  end

  def send_to_admin(msg)
    User.find(ADMIN_ID).messages.create(text: msg, is_incoming: false)
  end
end
