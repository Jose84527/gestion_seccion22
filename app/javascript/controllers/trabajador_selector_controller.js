import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "query",
    "results",
    "hiddenInput",
    "selectedBox",
    "selectedText",
    "submit",
    "roleSelect",
    "cuentaField",
    "cuentaSelect",
    "cuentaHelper"
  ]

  static values = { url: String }

  connect() {
    this.timeout = null
    this.updateSelectionState()
    this.toggleCuentaFinanciera()
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  search() {
    if (!this.hasQueryTarget) return

    const term = this.queryTarget.value.trim()

    if (this.timeout) clearTimeout(this.timeout)

    if (term.length < 2) {
      this.clearResults()
      return
    }

    this.timeout = setTimeout(() => {
      this.performSearch(term)
    }, 250)
  }

  async performSearch(term) {
    if (!this.hasUrlValue) return

    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(term)}`, {
        headers: { Accept: "application/json" }
      })

      if (!response.ok) {
        throw new Error("No se pudo completar la búsqueda")
      }

      const results = await response.json()
      this.renderResults(results)
    } catch (_error) {
      this.renderResults([])
    }
  }

  renderResults(results) {
    if (!this.hasResultsTarget) return

    this.resultsTarget.innerHTML = ""

    if (results.length === 0) {
      const empty = document.createElement("div")
      empty.className = "trabajador-selector__empty"
      empty.textContent = "No se encontraron trabajadores disponibles."
      this.resultsTarget.appendChild(empty)
      this.resultsTarget.hidden = false
      return
    }

    results.forEach((item) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "trabajador-selector__item"
      button.dataset.action = "click->trabajador-selector#select"
      button.dataset.id = item.id
      button.dataset.label = item.etiqueta

      const title = document.createElement("span")
      title.className = "trabajador-selector__item-title"
      title.textContent = item.nombre

      const meta = document.createElement("span")
      meta.className = "trabajador-selector__item-meta"
      meta.textContent = `${item.rfc} · ${item.clave_cobro}`

      button.appendChild(title)
      button.appendChild(meta)

      this.resultsTarget.appendChild(button)
    })

    this.resultsTarget.hidden = false
  }

  select(event) {
    const button = event.currentTarget
    const id = button.dataset.id
    const label = button.dataset.label

    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = id
    }

    if (this.hasSelectedTextTarget) {
      this.selectedTextTarget.textContent = label
    }

    if (this.hasSelectedBoxTarget) {
      this.selectedBoxTarget.hidden = false
    }

    if (this.hasQueryTarget) {
      this.queryTarget.value = ""
    }

    this.clearResults()
    this.updateSelectionState()
  }

  clearSelection() {
    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = ""
    }

    if (this.hasSelectedTextTarget) {
      this.selectedTextTarget.textContent = ""
    }

    if (this.hasSelectedBoxTarget) {
      this.selectedBoxTarget.hidden = true
    }

    if (this.hasQueryTarget) {
      this.queryTarget.value = ""
    }

    this.clearResults()
    this.updateSelectionState()

    if (this.hasQueryTarget) {
      this.queryTarget.focus()
    }
  }

  clearResults() {
    if (!this.hasResultsTarget) return

    this.resultsTarget.innerHTML = ""
    this.resultsTarget.hidden = true
  }

  updateSelectionState() {
    if (!this.hasHiddenInputTarget) return

    const hasSelection = this.hiddenInputTarget.value.trim() !== ""

    if (this.hasSelectedBoxTarget) {
      this.selectedBoxTarget.hidden = !hasSelection
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = !hasSelection
    }
  }

  toggleCuentaFinanciera() {
    if (!this.hasRoleSelectTarget || !this.hasCuentaSelectTarget) return

    const rol = this.roleSelectTarget.value
    const esFinanzas = rol === "finanzas"

    this.cuentaSelectTarget.disabled = !esFinanzas

    if (!esFinanzas) {
      this.cuentaSelectTarget.value = ""
    }

    if (this.hasCuentaFieldTarget) {
      this.cuentaFieldTarget.classList.toggle("is-disabled", !esFinanzas)
    }

    if (this.hasCuentaHelperTarget) {
      this.cuentaHelperTarget.textContent = esFinanzas
        ? "Obligatoria para usuarios con rol Finanzas."
        : "No se requiere cuenta financiera para administradores."
    }
  }
}