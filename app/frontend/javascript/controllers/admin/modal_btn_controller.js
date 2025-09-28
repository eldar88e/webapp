import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { name: { type: String, default: 'modal' } };

  open() {
    const modal = document.getElementById(this.nameValue);
    setTimeout(() => {
      modal.classList.remove("hidden");
      modal.removeAttribute("aria-hidden");
      if (this.nameValue === 'modal') {
        document.getElementById("body").classList.add("blur-xs");
        document.getElementById("header").classList.add("blur-xs");
      }
    }, 100);
  }
}
