require_dependency File.expand_path('../lib/redmine_kanban/hooks', __FILE__)
require_dependency File.expand_path('../lib/kanban_board', __FILE__)

Redmine::Plugin.register :redmine_kanban do
  name        'Redmine Kanban'
  author      'yavnaumov@gmail.com'
  description 'Kanban board view for Redmine issues with drag-and-drop'
  version     '0.0.1'

  requires_redmine version_or_higher: '5.0.0'

  menu :project_menu, :kanban,
       { controller: 'kanban', action: 'index' },
       caption: :label_kanban,
       after: :activity,
       param: :id

  project_module :kanban do
    # View board
    permission :view_kanban,
               { kanban: [:index, :get_issues] },
               require: :member

    # Move cards (drag & drop)
    permission :move_kanban,
               { kanban: [:move_issue] },
               require: :member

    # Change board settings
    permission :manage_kanban_settings,
               { kanban: [:settings, :update_settings] },
               require: :member
  end

  settings default: {
    'enable_kanban'          => '1',
    'show_assignee'          => '1',
    'show_priority'          => '1',
    'show_estimated_hours'   => '1'
  }, partial: 'settings/kanban_settings'
end
