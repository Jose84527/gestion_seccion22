import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "hiddenInput", "selectedBox", "selectedText", "submit"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.updateSelectionState()
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  search() {
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

    this.hiddenInputTarget.value = id
    this.selectedTextTarget.textContent = label
    this.selectedBoxTarget.hidden = false
    this.queryTarget.value = ""

    this.clearResults()
    this.updateSelectionState()
  }

  clearSelection() {
    this.hiddenInputTarget.value = ""
    this.selectedTextTarget.textContent = ""
    this.selectedBoxTarget.hidden = true
    this.queryTarget.value = ""

    this.clearResults()
    this.updateSelectionState()
    this.queryTarget.focus()
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.hidden = true
  }

  updateSelectionState() {
    const hasSelection = this.hiddenInputTarget.value.trim() !== ""

    if (this.hasSelectedBoxTarget) {
      this.selectedBoxTarget.hidden = !hasSelection
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = !hasSelection
    }
  }
}