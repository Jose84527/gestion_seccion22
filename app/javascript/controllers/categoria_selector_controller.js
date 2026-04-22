import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "monto"]

  connect() {
    this.actualizarMonto()
  }

  actualizarMonto() {
    if (!this.hasSelectTarget || !this.hasMontoTarget) return

    const selectedOption = this.selectTarget.options[this.selectTarget.selectedIndex]
    const monto = selectedOption?.dataset?.monto

    if (!monto) {
      this.montoTarget.value = ""
      return
    }

    const numero = Number(monto)
    if (Number.isNaN(numero)) {
      this.montoTarget.value = ""
      return
    }

    this.montoTarget.value = new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN"
    }).format(numero)
  }
}