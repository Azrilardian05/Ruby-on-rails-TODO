class Task < ApplicationRecord
  validates :title, presence: true

  def toggle_completed!
    update!(completed: !completed?)
  end
end
