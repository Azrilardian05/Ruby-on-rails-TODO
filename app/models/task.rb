class Task < ApplicationRecord
  STATUS_FILTERS = %w[all active completed].freeze
  SORT_FIELDS = %w[created_at due_date].freeze
  SORT_DIRECTIONS = %w[asc desc].freeze

  DEFAULT_STATUS = "all".freeze
  DEFAULT_SORT = "created_at".freeze
  # Newest tasks first; earliest deadline first.
  DEFAULT_DIRECTIONS = { "created_at" => "desc", "due_date" => "asc" }.freeze

  validates :title, presence: true

  scope :active, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }

  # Filter by status: "all" (or anything unknown) returns every task.
  scope :with_status, ->(status) {
    case status.to_s
    when "active" then active
    when "completed" then completed
    else all
    end
  }

  scope :by_created_at, ->(direction = :desc) {
    dir = Task.normalize_direction(direction, DEFAULT_DIRECTIONS["created_at"])
    order(created_at: dir, id: dir)
  }

  # Tasks without a due date always come last, regardless of direction.
  scope :by_due_date, ->(direction = :asc) {
    dir = Task.normalize_direction(direction, DEFAULT_DIRECTIONS["due_date"])
    order(Arel.sql("tasks.due_date IS NULL"), due_date: dir, id: dir)
  }

  # Sort by "created_at" or "due_date"; unknown values fall back to the default.
  scope :sorted_by, ->(field, direction = nil) {
    case field.to_s
    when "due_date" then by_due_date(direction)
    else by_created_at(direction)
    end
  }

  def self.normalize_direction(direction, default)
    direction = direction.to_s.downcase
    SORT_DIRECTIONS.include?(direction) ? direction.to_sym : default.to_sym
  end

  def toggle_completed!
    update!(completed: !completed?)
  end
end
