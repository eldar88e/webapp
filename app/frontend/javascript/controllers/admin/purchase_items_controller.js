import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["items", "template"]

  add(event) {
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.itemsTarget.insertAdjacentHTML("beforeend", content)
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest("[data-purchase-items-target='item']")
    if (item.dataset.new === "true") {
      item.remove()
    } else {
      item.querySelector("input[name*='_destroy']").value = "1"
      item.style.display = "none"
    }
  }
}
