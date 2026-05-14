class AgregarActaPdfPathAEventos < ActiveRecord::Migration[8.1]
  def change
    add_column :eventos, :acta_pdf_path, :string unless column_exists?(:eventos, :acta_pdf_path)
  end
end