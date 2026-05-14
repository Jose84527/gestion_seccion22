import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "query",
    "tableBody",
    "pagination",
    "meta",
    "selectedList",
    "selectedTemplate",
    "selectedItem",
    "emptySelected"
  ]

  static values = { url: String }

  connect() {
    this.timeout = null
    this.currentPage = 1
    this.currentQuery = ""
    this.lastMeta = {
      pagina_actual: 1,
      total_paginas: 1,
      total_registros: 0
    }

    this.loadSelectedFromDom()
    this.updateSelectedState()
    this.loadPage(1)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  search() {
    if (!this.hasQueryTarget) return

    if (this.timeout) clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      this.currentQuery = this.queryTarget.value.trim()
      this.loadPage(1)
    }, 300)
  }

  async loadPage(page) {
    if (!this.hasUrlValue) return

    this.currentPage = page

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("page", page)

    if (this.currentQuery.length > 0) {
      url.searchParams.set("q", this.currentQuery)
    }

    this.setLoading()

    try {
      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" }
      })

      if (!response.ok) {
        throw new Error("No se pudo cargar la lista de trabajadores")
      }

      const data = await response.json()

      this.lastMeta = {
        pagina_actual: data.pagina_actual || 1,
        total_paginas: data.total_paginas || 1,
        total_registros: data.total_registros || 0
      }

      this.renderTable(data.trabajadores || [])
      this.renderPagination(this.lastMeta.pagina_actual, this.lastMeta.total_paginas)
      this.renderMeta()
      this.updateSelectedState()
    } catch (_error) {
      this.renderError()
    }
  }

  loadSelectedFromDom() {
    this.selected = new Map()

    if (!this.hasSelectedItemTarget) return

    this.selectedItemTargets.forEach((item) => {
      this.selected.set(String(item.dataset.trabajadorId), {
        id: String(item.dataset.trabajadorId),
        nombre: item.dataset.nombre,
        meta: item.dataset.meta
      })
    })
  }

  setLoading() {
    if (this.hasTableBodyTarget) {
      this.tableBodyTarget.innerHTML = `
        <tr>
          <td colspan="5">Cargando trabajadores...</td>
        </tr>
      `
    }

    if (this.hasMetaTarget) {
      this.metaTarget.textContent = "Cargando trabajadores..."
    }

    if (this.hasPaginationTarget) {
      this.paginationTarget.innerHTML = ""
    }
  }

  renderTable(trabajadores) {
    if (!this.hasTableBodyTarget) return

    this.tableBodyTarget.innerHTML = ""

    if (trabajadores.length === 0) {
      this.tableBodyTarget.innerHTML = `
        <tr>
          <td colspan="5">No se encontraron trabajadores activos.</td>
        </tr>
      `
      return
    }

    trabajadores.forEach((trabajador) => {
      const id = String(trabajador.id)
      const checked = this.selected.has(id) ? "checked" : ""

      const row = document.createElement("tr")

      row.innerHTML = `
        <td>
          <input
            type="checkbox"
            ${checked}
            data-action="change->evento-asistentes-selector#toggle"
            data-id="${this.escapeHtml(id)}"
            data-nombre="${this.escapeHtml(trabajador.nombre)}"
            data-meta="${this.escapeHtml(`${trabajador.rfc} · ${trabajador.clave_cobro}`)}"
          >
        </td>
        <td><strong>${this.escapeHtml(trabajador.nombre)}</strong></td>
        <td>${this.escapeHtml(trabajador.rfc || "-")}</td>
        <td>${this.escapeHtml(trabajador.clave_cobro || "-")}</td>
        <td>${this.escapeHtml(trabajador.tipo_trabajador || "-")}</td>
      `

      this.tableBodyTarget.appendChild(row)
    })
  }

  renderPagination(currentPage, totalPages) {
    if (!this.hasPaginationTarget) return

    this.paginationTarget.innerHTML = ""

    if (totalPages <= 1) return

    if (currentPage > 1) {
      this.paginationTarget.appendChild(
        this.paginationButton("← Anterior", currentPage - 1)
      )
    }

    for (let page = 1; page <= totalPages; page += 1) {
      const button = this.paginationButton(String(page), page)

      if (page === currentPage) {
        button.classList.add("is-active")
      }

      this.paginationTarget.appendChild(button)
    }

    if (currentPage < totalPages) {
      this.paginationTarget.appendChild(
        this.paginationButton("Siguiente →", currentPage + 1)
      )
    }
  }

  paginationButton(label, page) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "pagination__link"
    button.textContent = label
    button.addEventListener("click", () => this.loadPage(page))

    return button
  }

  renderMeta() {
    if (!this.hasMetaTarget) return

    const total = this.lastMeta.total_registros || 0
    const page = this.lastMeta.pagina_actual || 1
    const totalPages = this.lastMeta.total_paginas || 1
    const selectedCount = this.selected.size

    this.metaTarget.textContent =
      `Mostrando página ${page} de ${totalPages}. Trabajadores encontrados: ${total}. Seleccionados: ${selectedCount}.`
  }

  renderError() {
    if (this.hasTableBodyTarget) {
      this.tableBodyTarget.innerHTML = `
        <tr>
          <td colspan="5">No se pudo cargar la lista de trabajadores.</td>
        </tr>
      `
    }

    if (this.hasMetaTarget) {
      this.metaTarget.textContent = "Error al cargar trabajadores."
    }
  }

  toggle(event) {
    const checkbox = event.currentTarget
    const id = String(checkbox.dataset.id)

    if (checkbox.checked) {
      this.addSelected({
        id: id,
        nombre: checkbox.dataset.nombre,
        meta: checkbox.dataset.meta
      })
    } else {
      this.removeById(id)
    }

    this.updateSelectedState()
    this.renderMeta()
  }

  addSelected(trabajador) {
    if (this.selected.has(String(trabajador.id))) return

    this.selected.set(String(trabajador.id), trabajador)

    const html = this.selectedTemplateTarget.innerHTML
      .replaceAll("TRABAJADOR_ID", this.escapeHtml(trabajador.id))
      .replaceAll("TRABAJADOR_NOMBRE", this.escapeHtml(trabajador.nombre))
      .replaceAll("TRABAJADOR_META", this.escapeHtml(trabajador.meta))

    this.selectedListTarget.insertAdjacentHTML("beforeend", html)
  }

  removeSelected(event) {
    const item = event.currentTarget.closest("[data-evento-asistentes-selector-target='selectedItem']")
    if (!item) return

    this.removeById(item.dataset.trabajadorId)
    this.updateSelectedState()
    this.syncCheckboxes()
    this.renderMeta()
  }

  removeById(id) {
    const idString = String(id)

    this.selected.delete(idString)

    const item = this.selectedItemTargets.find((selectedItem) => {
      return selectedItem.dataset.trabajadorId === idString
    })

    if (item) item.remove()
  }

  updateSelectedState() {
    if (!this.hasEmptySelectedTarget) return

    const haySeleccionados = this.selected.size > 0

    this.emptySelectedTarget.hidden = haySeleccionados
    this.emptySelectedTarget.style.display = haySeleccionados ? "none" : ""
  }

  syncCheckboxes() {
    if (!this.hasTableBodyTarget) return

    const checkboxes = this.tableBodyTarget.querySelectorAll("input[type='checkbox']")

    checkboxes.forEach((checkbox) => {
      checkbox.checked = this.selected.has(String(checkbox.dataset.id))
    })
  }

  escapeHtml(value) {
    return String(value || "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;")
  }
}