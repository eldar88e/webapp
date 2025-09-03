import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["spinner", "content"];

  show() {
    this.spinnerTarget.style.display = "flex";
    this.contentTarget.classList.add("hidden");
  }
}
