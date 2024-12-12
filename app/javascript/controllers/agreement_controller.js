import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "agreement", "check_box"];

  visible(event) {
    event.preventDefault();
    this.agreementTarget.style = "display: block;"
    this.formTarget.style = "display: none;"
    document.getElementById('modal').classList.remove('left');
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  agree(event) {
    event.preventDefault();
    this.check_boxTarget.checked = true;
    this.formTarget.style = "display: block;"
    this.agreementTarget.style = "display: none;"
    document.getElementById('modal').classList.add('left');
  }

  close() {
    this.formTarget.style = "display: block;"
    this.agreementTarget.style = "display: none;"
    document.getElementById('modal').classList.add('left');
  }
}
