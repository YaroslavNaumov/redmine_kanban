RedmineApp::Application.routes.draw do
  scope '/projects/:id' do
    get  'kanban',                   to: 'kanban#index',           as: 'project_kanban'
    get  'kanban/settings',          to: 'kanban#settings',        as: 'project_kanban_settings'
    post 'kanban/settings',          to: 'kanban#update_settings', as: 'project_kanban_update_settings'
    post 'kanban/move_issue',        to: 'kanban#move_issue',      as: 'project_kanban_move_issue'
    get  'kanban/issues',            to: 'kanban#get_issues',      as: 'project_kanban_issues'
  end
end
