require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid with only a title" do
    assert Task.new(title: "Buy milk").valid?
  end

  test "invalid without a title" do
    task = Task.new(title: nil)

    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "invalid with a blank title" do
    assert_not Task.new(title: "   ").valid?
  end

  test "completed defaults to false" do
    assert_equal false, Task.new.completed
    assert_equal false, Task.create!(title: "New task").reload.completed
  end

  test "description and due_date are optional" do
    task = Task.create!(title: "Minimal")

    assert_nil task.description
    assert_nil task.due_date
  end

  test "stores description and due_date" do
    task = Task.create!(title: "Full", description: "Details", due_date: Date.new(2026, 12, 31))

    assert_equal "Details", task.reload.description
    assert_equal Date.new(2026, 12, 31), task.due_date
  end

  test "fixtures are valid" do
    Task.all.each { |task| assert task.valid?, task.errors.full_messages.to_sentence }
  end

  # --- filter & sort scopes ---

  def reset_tasks!
    Task.delete_all
  end

  test "active and completed scopes split tasks by completion" do
    reset_tasks!
    todo = Task.create!(title: "Todo")
    done = Task.create!(title: "Done", completed: true)

    assert_equal [ todo ], Task.active.to_a
    assert_equal [ done ], Task.completed.to_a
  end

  test "with_status filters by all, active and completed" do
    reset_tasks!
    todo = Task.create!(title: "Todo")
    done = Task.create!(title: "Done", completed: true)

    assert_equal [ todo, done ].sort_by(&:id), Task.with_status("all").order(:id).to_a
    assert_equal [ todo ], Task.with_status("active").to_a
    assert_equal [ done ], Task.with_status("completed").to_a
    assert_equal 2, Task.with_status(nil).count
    assert_equal 2, Task.with_status("bogus").count
  end

  test "by_created_at orders newest first by default and oldest first with asc" do
    reset_tasks!
    old = Task.create!(title: "Old", created_at: 3.days.ago)
    mid = Task.create!(title: "Mid", created_at: 2.days.ago)
    new = Task.create!(title: "New", created_at: 1.day.ago)

    assert_equal [ new, mid, old ], Task.by_created_at.to_a
    assert_equal [ old, mid, new ], Task.by_created_at(:asc).to_a
    assert_equal [ new, mid, old ], Task.by_created_at("garbage").to_a
  end

  test "by_due_date orders earliest first by default and puts tasks without due date last" do
    reset_tasks!
    none = Task.create!(title: "None")
    late = Task.create!(title: "Late", due_date: Date.new(2026, 12, 31))
    soon = Task.create!(title: "Soon", due_date: Date.new(2026, 11, 1))

    assert_equal [ soon, late, none ], Task.by_due_date.to_a
    assert_equal [ late, soon, none ], Task.by_due_date(:desc).to_a
  end

  test "sorted_by dispatches on field and falls back to created_at" do
    reset_tasks!
    a = Task.create!(title: "A", due_date: Date.new(2026, 12, 1), created_at: 2.days.ago)
    b = Task.create!(title: "B", due_date: Date.new(2026, 11, 1), created_at: 1.day.ago)

    assert_equal [ b, a ], Task.sorted_by("due_date").to_a
    assert_equal [ a, b ], Task.sorted_by("due_date", "desc").to_a
    assert_equal [ b, a ], Task.sorted_by("created_at").to_a
    assert_equal [ a, b ], Task.sorted_by("created_at", "asc").to_a
    assert_equal [ b, a ], Task.sorted_by("unknown").to_a
  end

  test "scopes can be chained" do
    reset_tasks!
    Task.create!(title: "Done", completed: true, due_date: Date.new(2026, 11, 1))
    later = Task.create!(title: "Later", due_date: Date.new(2026, 12, 1))
    sooner = Task.create!(title: "Sooner", due_date: Date.new(2026, 11, 15))

    assert_equal [ sooner, later ], Task.with_status("active").sorted_by("due_date").to_a
  end
end
