import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["items", "template"];

  add() {
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime(),
    );
    this.itemsTarget.insertAdjacentHTML("beforeend", content);
  }

  remove(event) {
    const item = event.target.closest("[data-purchase-expenses-target='item']");
    const destroyField = item.querySelector("input[name*='_destroy']");
    if (destroyField) {
      destroyField.value = 1;
      item.style.display = "none";
    }
  }
}
