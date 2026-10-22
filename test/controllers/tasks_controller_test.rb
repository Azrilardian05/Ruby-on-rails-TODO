require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
  end

  test "routes are registered" do
    assert_routing "/tasks", controller: "tasks", action: "index"
    assert_routing({ method: "post", path: "/tasks" }, controller: "tasks", action: "create")
    assert_routing "/tasks/new", controller: "tasks", action: "new"
    assert_routing "/tasks/1", controller: "tasks", action: "show", id: "1"
    assert_routing "/tasks/1/edit", controller: "tasks", action: "edit", id: "1"
    assert_routing({ method: "patch", path: "/tasks/1" }, controller: "tasks", action: "update", id: "1")
    assert_routing({ method: "delete", path: "/tasks/1" }, controller: "tasks", action: "destroy", id: "1")
  end

  test "should get index" do
    get tasks_url
    assert_response :success
    assert_select "li", minimum: Task.count
    assert_select "a", text: @task.title
  end

  test "should get new" do
    get new_task_url
    assert_response :success
    assert_select "form"
  end

  test "should create task" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: { task: { title: "New task", description: "Desc", completed: "1", due_date: "2026-12-01" } }
    end

    task = Task.order(:id).last
    assert_redirected_to task_url(task)
    assert_equal "New task", task.title
    assert task.completed?
    assert_equal Date.new(2026, 12, 1), task.due_date
  end

  test "should not create invalid task" do
    assert_no_difference("Task.count") do
      post tasks_url, params: { task: { title: "" } }
    end

    assert_response :unprocessable_content
  end

  test "create requires task params" do
    assert_no_difference("Task.count") do
      post tasks_url, params: {}
    end

    assert_response :bad_request
  end

  test "create ignores unpermitted params" do
    post tasks_url, params: { task: { title: "Mass assign", id: 999_999, created_at: "2000-01-01" } }

    task = Task.find_by!(title: "Mass assign")
    assert_not_equal 999_999, task.id
    assert_operator task.created_at.year, :>, 2000
  end

  test "should show task" do
    get task_url(@task)
    assert_response :success
    assert_select "h1", @task.title
  end

  test "should get edit" do
    get edit_task_url(@task)
    assert_response :success
    assert_select "form"
  end

  test "should update task" do
    patch task_url(@task), params: { task: { title: "Updated", completed: "1" } }

    assert_redirected_to task_url(@task)
    @task.reload
    assert_equal "Updated", @task.title
    assert @task.completed?
  end

  test "should not update with invalid data" do
    patch task_url(@task), params: { task: { title: "" } }

    assert_response :unprocessable_content
    assert_equal "Write documentation", @task.reload.title
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end

    assert_redirected_to tasks_url
  end

  test "missing task returns not found" do
    get task_url(id: 0)
    assert_response :not_found
  end

  test "index shows task details and empty state" do
    get tasks_url
    assert_select "#tasks li", Task.count
    assert_select "#tasks .badge-done", text: "Done"

    Task.delete_all
    get tasks_url
    assert_select "#tasks", false
    assert_select ".empty-state"
  end

  test "flash is shown after create" do
    post tasks_url, params: { task: { title: "Flash me" } }
    follow_redirect!
    assert_select ".flash-notice", "Task was successfully created."
  end

  test "flash is shown after update" do
    patch task_url(@task), params: { task: { title: "Renamed" } }
    follow_redirect!
    assert_select ".flash-notice", "Task was successfully updated."
  end

  test "flash is shown after destroy" do
    delete task_url(@task)
    follow_redirect!
    assert_select ".flash-notice", "Task was successfully deleted."
  end

  test "create shows validation errors in the form" do
    post tasks_url, params: { task: { title: "" } }
    assert_response :unprocessable_content
    assert_select "#error_explanation li", "Title can't be blank"
    assert_select ".field_with_errors input#task_title"
  end

  test "update shows validation errors in the form" do
    patch task_url(@task), params: { task: { title: "" } }
    assert_response :unprocessable_content
    assert_select "#error_explanation li", "Title can't be blank"
  end

  test "toggle route is registered" do
    assert_routing({ method: "patch", path: "/tasks/1/toggle" }, controller: "tasks", action: "toggle", id: "1")
  end

  test "toggle marks an active task as completed" do
    assert_not @task.completed?
    patch toggle_task_url(@task)

    assert_redirected_to tasks_url
    assert @task.reload.completed?
  end

  test "toggle reverts a completed task to active" do
    done = tasks(:two)
    assert done.completed?
    patch toggle_task_url(done)

    assert_redirected_to tasks_url
    assert_not done.reload.completed?
  end

  test "toggle twice restores the original state" do
    patch toggle_task_url(@task)
    patch toggle_task_url(@task)
    assert_not @task.reload.completed?
  end

  test "toggle does not change other attributes" do
    assert_no_changes -> { @task.reload.slice(:title, :description, :due_date) } do
      patch toggle_task_url(@task)
    end
  end

  test "toggle redirects back to the referring page" do
    patch toggle_task_url(@task), headers: { "HTTP_REFERER" => task_url(@task) }
    assert_redirected_to task_url(@task)
  end

  test "toggle shows a flash message" do
    patch toggle_task_url(@task)
    follow_redirect!
    assert_select ".flash-notice", "Task marked as done."
  end

  test "toggle for a missing task returns not found" do
    patch toggle_task_url(id: 0)
    assert_response :not_found
  end

  test "index renders a toggle button per task" do
    get tasks_url
    assert_select "#tasks li", Task.count
    assert_select "##{ActionView::RecordIdentifier.dom_id(@task)} form[action='#{toggle_task_path(@task)}']"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@task)} button[aria-pressed='false']"
  end

  test "index renders completed tasks differently" do
    done = tasks(:two)
    get tasks_url
    assert_select "##{ActionView::RecordIdentifier.dom_id(done)}.is-completed .badge-done"
    assert_select "##{ActionView::RecordIdentifier.dom_id(done)} button[aria-pressed='true']"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@task)}.is-completed", false
  end

  # --- filter & sort ---

  def listed_titles
    css_select("#tasks .task-title").map(&:text)
  end

  def seed_filter_tasks
    Task.delete_all
    Task.create!(title: "Alpha", due_date: Date.new(2026, 12, 1), created_at: 3.days.ago)
    Task.create!(title: "Bravo", completed: true, due_date: Date.new(2026, 11, 1), created_at: 2.days.ago)
    Task.create!(title: "Charlie", created_at: 1.day.ago)
  end

  test "index shows all tasks by default, newest first" do
    seed_filter_tasks
    get tasks_url
    assert_equal %w[Charlie Bravo Alpha], listed_titles
  end

  test "index filters active tasks" do
    seed_filter_tasks
    get tasks_url, params: { status: "active" }
    assert_equal %w[Charlie Alpha], listed_titles
    assert_select "a.filter-tab.is-current", text: "Active"
  end

  test "index filters completed tasks" do
    seed_filter_tasks
    get tasks_url, params: { status: "completed" }
    assert_equal %w[Bravo], listed_titles
    assert_select "a.filter-tab.is-current", text: "Completed"
  end

  test "index status all shows everything" do
    seed_filter_tasks
    get tasks_url, params: { status: "all" }
    assert_equal 3, listed_titles.size
  end

  test "index sorts by due date ascending by default with undated last" do
    seed_filter_tasks
    get tasks_url, params: { sort: "due_date" }
    assert_equal %w[Bravo Alpha Charlie], listed_titles
  end

  test "index sorts by due date descending with undated last" do
    seed_filter_tasks
    get tasks_url, params: { sort: "due_date", direction: "desc" }
    assert_equal %w[Alpha Bravo Charlie], listed_titles
  end

  test "index sorts by created date ascending" do
    seed_filter_tasks
    get tasks_url, params: { sort: "created_at", direction: "asc" }
    assert_equal %w[Alpha Bravo Charlie], listed_titles
  end

  test "index combines filter and sort" do
    seed_filter_tasks
    get tasks_url, params: { status: "active", sort: "due_date" }
    assert_equal %w[Alpha Charlie], listed_titles
  end

  test "index ignores invalid filter and sort params" do
    seed_filter_tasks
    get tasks_url, params: { status: "'; DROP TABLE tasks", sort: "title; --", direction: "sideways" }
    assert_response :success
    assert_equal %w[Charlie Bravo Alpha], listed_titles
  end

  test "index shows an empty state for an empty filter" do
    Task.delete_all
    Task.create!(title: "Only active")
    get tasks_url, params: { status: "completed" }
    assert_response :success
    assert_select ".empty-state", text: /No completed tasks/
  end
end
