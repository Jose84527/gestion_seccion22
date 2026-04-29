import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tipo", "montoWrapper", "porcentajeWrapper", "monto", "porcentaje"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasTipoTarget) return

    const tipo = this.tipoTarget.value

    const usaMonto = tipo === "fija" || tipo === "mixta"
    const usaPorcentaje = tipo === "porcentaje" || tipo === "mixta"

    this.setFieldState(this.montoWrapperTarget, this.montoTarget, usaMonto)
    this.setFieldState(this.porcentajeWrapperTarget, this.porcentajeTarget, usaPorcentaje)
  }

  setFieldState(wrapper, input, enabled) {
    wrapper.hidden = !enabled
    input.disabled = !enabled

    if (!enabled) {
      input.value = ""
    }
  }
}