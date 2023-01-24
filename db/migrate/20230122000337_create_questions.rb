class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.string :question, :limit => 140, :default => "", :null => true
      t.string :context, :default => "", :null => true
      t.string :answer, :limit => 1000, :default => "", :null => true
      t.integer :ask_count, :default => 1
      t.timestamps
    end
  end
end