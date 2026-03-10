class CreateKanbanBoards < ActiveRecord::Migration[6.1]
  def change
    create_table :kanban_boards do |t|
      t.integer  :project_id,           null: false
      t.string   :name,                 null: false, default: ''
      t.text     :description
      t.boolean  :enabled,              null: false, default: true
      t.boolean  :show_assignee,        null: false, default: true
      t.boolean  :show_priority,        null: false, default: true
      t.boolean  :show_estimated_hours, null: false, default: true
      t.boolean  :show_spent_hours,     null: false, default: true
      t.boolean  :hide_closed_columns,  null: false, default: true
      t.timestamps null: false
    end

    add_index :kanban_boards, :project_id, unique: true
    add_foreign_key :kanban_boards, :projects, on_delete: :cascade
  end
end
