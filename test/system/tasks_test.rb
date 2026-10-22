require "application_system_test_case"

class TasksTest < ApplicationSystemTestCase
  setup do
    Task.delete_all
  end

  test "adding a task" do
    visit tasks_path
    assert_text "No tasks yet"

    click_on "New task"
    fill_in "Title", with: "Buy milk"
    fill_in "Description", with: "2 liters, semi-skimmed"
    click_on "Create Task"

    assert_text "Task was successfully created."
    assert_selector "h1", text: "Buy milk"
    assert_text "2 liters, semi-skimmed"
    assert_text "Pending"

    click_on "Back to tasks"
    assert_selector "#tasks .task-title", text: "Buy milk"
  end

  test "adding a task without a title shows a validation error" do
    visit new_task_path
    click_on "Create Task"

    assert_selector "#error_explanation", text: "Title can't be blank"
    assert_equal 0, Task.count
  end

  test "completing and reopening a task" do
    task = Task.create!(title: "Write report")

    visit tasks_path
    within "##{dom_id(task)}" do
      assert_text "Pending"
      click_button "Mark as done"
    end

    assert_text "Task marked as done."
    within "##{dom_id(task)}" do
      assert_text "Done"
      assert_selector ".badge-done"
    end
    assert task.reload.completed?

    within "##{dom_id(task)}" do
      click_button "Mark as pending"
    end

    assert_text "Task marked as pending."
    within "##{dom_id(task)}" do
      assert_text "Pending"
      assert_no_selector ".badge-done"
    end
    assert_not task.reload.completed?
  end

  test "editing a task" do
    task = Task.create!(title: "Old title", description: "Old description")

    visit tasks_path
    within("##{dom_id(task)}") { click_on "Edit" }

    fill_in "Title", with: "New title"
    fill_in "Description", with: "New description"
    click_on "Update Task"

    assert_text "Task was successfully updated."
    assert_selector "h1", text: "New title"
    assert_text "New description"
    assert_equal "New title", task.reload.title
  end

  test "editing a task with an empty title shows a validation error" do
    task = Task.create!(title: "Keep me")

    visit edit_task_path(task)
    fill_in "Title", with: ""
    click_on "Update Task"

    assert_selector "#error_explanation", text: "Title can't be blank"
    assert_equal "Keep me", task.reload.title
  end

  test "deleting a task from the list" do
    keep = Task.create!(title: "Keep this")
    doomed = Task.create!(title: "Delete this")

    visit tasks_path
    assert_selector "##{dom_id(doomed)}"

    accept_confirm("Are you sure?") do
      within("##{dom_id(doomed)}") { click_on "Delete" }
    end

    assert_text "Task was successfully deleted."
    assert_no_selector "##{dom_id(doomed)}"
    assert_selector "##{dom_id(keep)}"
    assert_not Task.exists?(doomed.id)
  end

  test "cancelling the delete confirmation keeps the task" do
    task = Task.create!(title: "Still here")

    visit tasks_path
    dismiss_confirm do
      within("##{dom_id(task)}") { click_on "Delete" }
    end

    assert_selector "##{dom_id(task)}"
    assert Task.exists?(task.id)
  end

  test "deleting a task from its detail page" do
    task = Task.create!(title: "Remove from show")

    visit task_path(task)
    accept_confirm { click_on "Delete" }

    assert_text "Task was successfully deleted."
    assert_current_path tasks_path
    assert_not Task.exists?(task.id)
  end

  test "filtering tasks by status" do
    Task.create!(title: "Open task")
    Task.create!(title: "Finished task", completed: true)

    visit tasks_path
    assert_text "Open task"
    assert_text "Finished task"

    click_on "Active"
    assert_text "Open task"
    assert_no_text "Finished task"
    assert_selector ".filter-tab.is-current", text: "Active"

    click_on "Completed"
    assert_text "Finished task"
    assert_no_text "Open task"
    assert_selector ".filter-tab.is-current", text: "Completed"

    click_on "All"
    assert_text "Open task"
    assert_text "Finished task"
  end

  test "a completed task leaves the active filter" do
    task = Task.create!(title: "Almost done")

    visit tasks_path(status: "active")
    within("##{dom_id(task)}") { click_button "Mark as done" }

    assert_text "Task marked as done."
    assert_no_selector "##{dom_id(task)}"
    assert_text "No active tasks."

    click_on "Completed"
    assert_selector "##{dom_id(task)}"
  end

  test "sorting tasks by due date" do
    Task.create!(title: "Later", due_date: Date.new(2030, 12, 1))
    Task.create!(title: "Sooner", due_date: Date.new(2030, 1, 1))
    Task.create!(title: "No date")

    visit tasks_path
    select "Due date", from: "Sort by"
    assert_current_path(/sort=due_date/)
    # The direction select keeps the default of the previous sort (descending).
    assert_equal [ "Later", "Sooner", "No date" ], task_titles

    select "Ascending", from: "direction"
    assert_current_path(/direction=asc/)
    assert_equal [ "Sooner", "Later", "No date" ], task_titles
  end

  test "full lifecycle: add, complete, edit and delete" do
    visit root_path
    click_on "Tasks"
    click_on "New task"
    fill_in "Title", with: "Lifecycle task"
    click_on "Create Task"
    assert_text "Task was successfully created."

    click_on "Back to tasks"
    click_button "Mark as done"
    assert_text "Task marked as done."
    assert_selector ".badge-done"

    click_on "Edit"
    fill_in "Title", with: "Lifecycle task (renamed)"
    click_on "Update Task"
    assert_text "Task was successfully updated."
    assert_text "Completed"

    click_on "Back to tasks"
    accept_confirm { click_on "Delete" }
    assert_text "Task was successfully deleted."
    assert_text "No tasks yet"
    assert_equal 0, Task.count
  end

  private

  def task_titles
    all("#tasks .task-title").map(&:text)
  end

  def dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end
end
