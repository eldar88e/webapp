import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "agreement", "check_box"];

  connect() {
  }

  visible(event) {
    event.preventDefault();
    this.agreementTarget.style = "display: block;"
    this.formTarget.style = "display: none;"
  }

  agree(event) {
    event.preventDefault();
    this.check_boxTarget.checked = true;
    this.formTarget.style = "display: block;"
    this.agreementTarget.style = "display: none;"
  }

  close() {
    this.formTarget.style = "display: block;"
    this.agreementTarget.style = "display: none;"
  }
}
