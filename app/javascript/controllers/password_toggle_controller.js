import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "visibleIcon", "hiddenIcon", "label"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"

    this.inputTarget.type = isPassword ? "text" : "password"
    this.visibleIconTarget.classList.toggle("is-hidden", isPassword)
    this.hiddenIconTarget.classList.toggle("is-hidden", !isPassword)
    this.labelTarget.textContent = isPassword ? "Ocultar contraseña" : "Mostrar contraseña"
  }
}