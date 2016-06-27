class AddStepThreeThroughFiveToAgreements < ActiveRecord::Migration[4.2]
  def change
    add_column :agreements, :has_read_step3, :boolean, null: false, default: false
    add_column :agreements, :posting_permission, :string
    add_column :agreements, :has_read_step5, :boolean, null: false, default: false
  end
end
