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
end
