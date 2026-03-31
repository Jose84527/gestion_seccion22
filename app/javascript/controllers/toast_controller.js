import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 2000 }
  }

  connect() {
    this.timeout = setTimeout(() => {
      this.close()
    }, this.delayValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  close() {
    this.element.classList.add("toast--closing")

    setTimeout(() => {
      this.element.remove()
    }, 220)
  }
}