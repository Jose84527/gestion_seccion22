class HomeController < ApplicationController
  before_action :autenticar_usuario, only: [:menu]
  def menu
  end
end
