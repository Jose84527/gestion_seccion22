class HomeController < ApplicationController
  before_action :autenticar_usuario

  def index
    if admin_actual?
      redirect_to menu_path
    end
  end

  def menu
  end
end