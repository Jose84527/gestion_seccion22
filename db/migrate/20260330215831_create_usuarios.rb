class CreateUsuarios < ActiveRecord::Migration[8.1]
  def change
    create_table :usuarios do |t|
      t.string :nombre_completo
      t.string :username
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
