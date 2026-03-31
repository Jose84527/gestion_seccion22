class HomeController < ApplicationController
  before_action :autenticar_usuario, only: :menu

  def index
  end

  def menu
  end
end