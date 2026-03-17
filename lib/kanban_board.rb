class KanbanBoard < ActiveRecord::Base
  belongs_to :project

  validates :project_id, presence: true, uniqueness: true
  validates :name, presence: true

  after_initialize :set_defaults, if: :new_record?

  scope :enabled, -> { where(enabled: true) }

  def self.for_project(project)
    find_or_create_by(project_id: project.id) do |board|
      board.name        = "#{project.name} Kanban"
      board.description = "Kanban board for #{project.name}"
    end
  end

# Returns all statuses (open + closed) that have tasks in the project,
# plus all open statuses so that empty columns are also shown.
# Options:
# assignee_id: Integer — filter by project member
  def get_issues_by_status(assignee_id: nil)
    result = {}
    get_statuses.each do |status|
      # Skipping closed columns if the hiding setting is enabled
      next if status.is_closed && cast_bool(hide_closed_columns)

      issues = get_issues_for_status(status.id, assignee_id: assignee_id)
      result[status.id] = {
        status:    status,
        issues:    issues,
        count:     issues.size,
        is_closed: status.is_closed
      }
    end
    result
  end

  # All open statuses + closed ones that have tasks in this project
  def get_statuses
    open_statuses = IssueStatus.sorted.reject(&:is_closed)
      closed_with_issues = IssueStatus
      .where(is_closed: true)
      .joins("INNER JOIN issues ON issues.status_id = issue_statuses.id")
      .merge(Issue.visible(User.current))
      .where("issues.project_id = ?", project_id)
      .distinct
      .order(:position)
  
    (open_statuses + closed_with_issues).uniq(&:id)
  end

  def get_issues_for_status(status_id, assignee_id: nil)
    scope = Issue.visible(User.current)
                 .where(project_id: project_id, status_id: status_id)
                 .includes(:assigned_to, :priority, :tracker, :time_entries)
                 .order('issues.id DESC')
    scope = scope.where(assigned_to_id: assignee_id) if assignee_id.present?
    scope
  end

  def format_issue(issue)
    {
      id:              issue.id,
      subject:         issue.subject,
      tracker:         issue.tracker.name,
      priority:        issue.priority.name,
      priority_id:     issue.priority.id,
      assigned_to:     issue.assigned_to&.name || '',
      estimated_hours: issue.estimated_hours,
      done_ratio:      issue.done_ratio,
      url:             "/issues/#{issue.id}"
    }
  end

  def display_settings
    {
      show_assignee:        cast_bool(show_assignee),
      show_priority:        cast_bool(show_priority),
      show_estimated_hours: cast_bool(show_estimated_hours),
      show_spent_hours:     cast_bool(show_spent_hours)
    }
  end

  private

  def cast_bool(val)
    ActiveRecord::Type::Boolean.new.cast(val)
  end

  def set_defaults
    self.name                 ||= project ? "#{project.name} Kanban" : 'Kanban'
    self.description          ||= ''
    self.enabled                = true  if self[:enabled].nil?
    self.show_assignee          = true  if self[:show_assignee].nil?
    self.show_priority          = true  if self[:show_priority].nil?
    self.show_estimated_hours   = true if self[:show_estimated_hours].nil?
    self.show_spent_hours       = true if self[:show_spent_hours].nil?
    self.hide_closed_columns    = false if self[:hide_closed_columns].nil?
  end
end
