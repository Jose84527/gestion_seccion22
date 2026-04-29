import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conceptos", "template"]

  addConcepto() {
    const index = new Date().getTime()
    const content = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", index)

    this.conceptosTarget.insertAdjacentHTML("beforeend", content)
  }

  removeConcepto(event) {
    event.preventDefault()

    const concepto = event.currentTarget.closest(".concepto-card")
    if (!concepto) return

    const destroyField = concepto.querySelector("input[name*='[_destroy]']")
    const idField = concepto.querySelector("input[name*='[id]']")

    if (destroyField && idField && idField.value) {
      destroyField.value = "1"
      concepto.setAttribute("hidden", "hidden")
      return
    }

    concepto.remove()
  }

  enableAllDisabledFields() {
    this.element.querySelectorAll("input:disabled, select:disabled, textarea:disabled").forEach((field) => {
      if (field.closest(".concepto-card")) {
        field.disabled = false
      }
    })
  }
}