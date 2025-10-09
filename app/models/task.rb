class Task < ApplicationRecord
  ADMIN_ID = 12

  has_rich_text :description

  has_many_attached :images
  has_many_attached :files

  has_many :comments, dependent: :destroy
  has_one :expense, as: :expenseable, dependent: :destroy

  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :user

  enum :stage, { idea: 0, approved: 1, in_progress: 2, reviewing: 3, done: 4 }
  enum :priority, { lowest: 0, low: 1, medium: 2, high: 3 }
  enum :category, { design: 0, dev: 1, marketing: 2 }
  enum :task_type, { sprint: 0, bugfix: 1, feature: 2 }

  validates :title, presence: true

  after_update :update_expense, if: -> { stage == 'done' && price.present? }

  after_commit :send_create_to_telegram, on: :create
  after_commit :send_update_to_telegram, on: :update

  private

  def send_create_to_telegram
    send_to_telegram "📋 Новая задача: #{title}"
  end

  def send_update_to_telegram
    send_to_telegram "📋 Задача ’’#{title}’’ обновлена"
  end

  def send_to_telegram(msg)
    msg += "\n\nСтатус: #{I18n.t("stage.#{stage}")}"
    msg += "\nПриоритет: #{I18n.t("priority.#{priority}")}"
    assignee.messages.create(text: msg, is_incoming: false)
    user.messages.create(text: msg, is_incoming: false) if assignee.id != user.id
    send_to_admin(msg)
  end

  def send_to_admin(msg)
    return if [assignee.id, user.id].include?(ADMIN_ID) || Rails.env.local?

    User.find(ADMIN_ID).messages.create(text: msg, is_incoming: false) if %w[approved reviewing done].include?(stage)
  end

  def update_expense
    exp = expense || build_expense
    exp.update(category: :development, description: title, amount: price)
  end
end
