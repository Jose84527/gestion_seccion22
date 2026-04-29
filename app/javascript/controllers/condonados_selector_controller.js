import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "results", "list", "template", "item"]
  static values = { url: String }

  connect() {
    this.timeout = null
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
      empty.textContent = "No se encontraron trabajadores activos."
      this.resultsTarget.appendChild(empty)
      this.resultsTarget.hidden = false
      return
    }

    results.forEach((item) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "trabajador-selector__item"
      button.dataset.action = "click->condonados-selector#select"
      button.dataset.id = item.id
      button.dataset.nombre = item.nombre
      button.dataset.meta = `${item.rfc} · ${item.clave_cobro} · ${item.tipo_trabajador || ""}`

      const title = document.createElement("span")
      title.className = "trabajador-selector__item-title"
      title.textContent = item.nombre

      const meta = document.createElement("span")
      meta.className = "trabajador-selector__item-meta"
      meta.textContent = button.dataset.meta

      button.appendChild(title)
      button.appendChild(meta)

      this.resultsTarget.appendChild(button)
    })

    this.resultsTarget.hidden = false
  }

  select(event) {
    event.preventDefault()

    const button = event.currentTarget
    const id = button.dataset.id

    if (this.exists(id)) {
      this.clearResults()
      this.queryTarget.value = ""
      return
    }

    const index = new Date().getTime()

    const html = this.templateTarget.innerHTML
      .replaceAll("NEW_RECORD", index)
      .replaceAll("TRABAJADOR_ID", id)
      .replaceAll("TRABAJADOR_NOMBRE", this.escapeHtml(button.dataset.nombre))
      .replaceAll("TRABAJADOR_META", this.escapeHtml(button.dataset.meta))

    this.listTarget.insertAdjacentHTML("beforeend", html)

    this.clearResults()
    this.queryTarget.value = ""
  }

  exists(id) {
    return this.itemTargets.some((item) => {
      return item.dataset.trabajadorId === id && !item.hidden
    })
  }

  removeExisting(event) {
    event.preventDefault()

    const item = event.currentTarget.closest(".condonado-item")
    if (!item) return

    const destroyField = item.querySelector("input[name*='[_destroy]']")

    if (destroyField) {
      destroyField.value = "1"
      item.hidden = true
      return
    }

    item.remove()
  }

  removeNew(event) {
    event.preventDefault()

    const item = event.currentTarget.closest(".condonado-item")
    if (!item) return

    item.remove()
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.hidden = true
  }

  escapeHtml(value) {
    const div = document.createElement("div")
    div.textContent = value || ""
    return div.innerHTML
  }
}