import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["spinner", "content"];

  show() {
    this.spinnerTarget.classList.remove("hidden");
    this.contentTarget.classList.add("hidden");
  }
}
