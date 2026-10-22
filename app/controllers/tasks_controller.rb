class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy toggle]

  def index
    @status = Task::STATUS_FILTERS.include?(params[:status]) ? params[:status] : Task::DEFAULT_STATUS
    @sort = Task::SORT_FIELDS.include?(params[:sort]) ? params[:sort] : Task::DEFAULT_SORT
    @direction = Task::SORT_DIRECTIONS.include?(params[:direction]) ? params[:direction] : Task::DEFAULT_DIRECTIONS[@sort]
    @tasks = Task.with_status(@status).sorted_by(@sort, @direction)
  end

  def show
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to @task, notice: "Task was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: "Task was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @task.destroy!
    redirect_to tasks_path, notice: "Task was successfully deleted.", status: :see_other
  end

  def toggle
    @task.toggle_completed!
    redirect_back_or_to tasks_path, status: :see_other,
      notice: @task.completed? ? "Task marked as done." : "Task marked as pending."
  end

  private

  def set_task
    @task = Task.find(params.expect(:id))
  end

  def task_params
    params.expect(task: [ :title, :description, :completed, :due_date ])
  end
end
