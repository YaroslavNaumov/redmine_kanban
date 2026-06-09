class KanbanController < ApplicationController
  before_action :find_project,           only: [:index, :settings, :update_settings, :move_issue, :get_issues]
  before_action :check_view_permission,  only: [:index, :get_issues]
  before_action :check_move_permission,  only: [:move_issue]
  before_action :check_manage_permission,only: [:settings, :update_settings]
  before_action :find_kanban_board,      only: [:index, :settings, :update_settings, :move_issue, :get_issues]
  before_action :check_board_enabled,    only: [:index, :move_issue, :get_issues]

  helper :issues
  helper :projects

  def index
    @members           = @project.members.includes(:user).map(&:user).sort_by(&:name)
    raw_assignee       = params[:assignee_id]
    @assignee_id       = raw_assignee.present? ? raw_assignee.to_i : nil
    @issues_by_status  = @kanban_board.get_issues_by_status(assignee_id: @assignee_id)
    @display_settings  = @kanban_board.display_settings
    @can_move          = User.current.allowed_to?(:move_kanban, @project) &&
                         User.current.allowed_to?(:edit_issues, @project)

    respond_to do |format|
      format.html
      format.json { render json: { success: true, statuses: format_statuses(@issues_by_status) } }
    end
  end

  def settings
    respond_to { |f| f.html }
  end

  def update_settings
    # Checkboxes are not sent by the browser when unchecked - we set them to false explicitly
    attrs = kanban_board_params.to_h
    %w[enabled show_assignee show_priority show_estimated_hours show_spent_hours hide_closed_columns].each do |field|
      attrs[field] = attrs[field].present? ? true : false
    end

    if @kanban_board.update(attrs)
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_kanban_settings_saved)
          redirect_to project_kanban_settings_path(@project)
        end
        format.json { render json: { success: true, message: l(:notice_kanban_settings_saved) } }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = l(:error_kanban_settings_failed)
          redirect_to project_kanban_settings_path(@project)
        end
        format.json { render json: { success: false, message: l(:error_kanban_settings_failed) }, status: :unprocessable_entity }
      end
    end
  end

  def move_issue
    issue_id      = params[:issue_id]
    new_status_id = params[:new_status_id]

    unless issue_id.present? && new_status_id.present?
      return render json: { success: false, message: l(:error_invalid_parameters) }, status: :bad_request
    end

    begin
      issue = Issue.find(issue_id)

      unless issue.editable?(User.current)
        return render json: { success: false, message: l(:error_kanban_issue_not_editable) }, status: :forbidden
      end

      unless issue.project_id == @project.id
        return render json: { success: false, message: l(:error_invalid_parameters) }, status: :bad_request
      end

      new_status = IssueStatus.find(new_status_id)

      unless status_transition_allowed?(issue, new_status)
        return render json: { success: false, message: l(:error_kanban_transition_not_allowed) }, status: :unprocessable_entity
      end

      # init_journal creates an entry in the task history (as with normal editing)
      issue.init_journal(User.current)
      issue.status = new_status
      if issue.save
        render json: {
          success: true,
          message: l(:notice_issue_updated),
          issue: { id: issue.id, subject: issue.subject, status_id: issue.status_id }
        }
      else
        render json: {
          success: false,
          message: l(:error_issue_update_failed),
          errors: issue.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: l(:error_issue_not_found) }, status: :not_found
    rescue => e
      Rails.logger.error("Kanban move_issue error: #{e.message}")
      render json: { success: false, message: l(:error_kanban_operation_failed) }, status: :internal_server_error
    end
  end

  def get_issues
    status_id = params[:status_id]

    unless status_id.present?
      return render json: { success: false, message: l(:error_invalid_parameters) }, status: :bad_request
    end

    begin
      issues      = @kanban_board.get_issues_for_status(status_id)
      issues_data = issues.map { |i| @kanban_board.format_issue(i) }
      render json: { success: true, issues: issues_data }
    rescue => e
      Rails.logger.error("Kanban get_issues error: #{e.message}")
      render json: { success: false, message: l(:error_kanban_operation_failed) }, status: :internal_server_error
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_kanban_board
    @kanban_board = KanbanBoard.for_project(@project)
  end

  def check_view_permission
    render_403 unless User.current.allowed_to?(:view_kanban, @project)
  end

  def check_move_permission
    unless User.current.allowed_to?(:move_kanban, @project) && User.current.allowed_to?(:edit_issues, @project)
      return render json: { success: false, message: l(:error_kanban_no_permission) }, status: :forbidden
    end
  end

  def check_manage_permission
    render_403 unless User.current.allowed_to?(:manage_kanban_settings, @project)
  end

  def check_board_enabled
    return if @kanban_board.enabled?

    respond_to do |format|
      format.html do
        if User.current.allowed_to?(:manage_kanban_settings, @project)
          flash[:warning] = l(:error_kanban_disabled)
          redirect_to project_kanban_settings_path(@project)
        else
          render_403
        end
      end
      format.json { render json: { success: false, message: l(:error_kanban_disabled) }, status: :forbidden }
    end
  end

  def format_statuses(statuses)
    statuses.map do |status_id, data|
      {
        id: status_id,
        name: data[:status].name,
        is_closed: data[:is_closed],
        count: data[:count],
        issues: data[:issues].map { |issue| @kanban_board.format_issue(issue) }
      }
    end
  end

  def status_transition_allowed?(issue, new_status)
    return true if issue.status_id == new_status.id
    return true unless workflow_defined_for_tracker?(issue.tracker_id)

    issue.new_statuses_allowed_to(User.current).include?(new_status)
  end

  def workflow_defined_for_tracker?(tracker_id)
    return true unless defined?(WorkflowTransition)

    WorkflowTransition.where(tracker_id: tracker_id).exists?
  end

  def kanban_board_params
    params.require(:kanban_board).permit(
      :name, :description, :enabled,
      :show_assignee, :show_priority, :show_estimated_hours, :show_spent_hours,
      :hide_closed_columns
    )
  end
end
