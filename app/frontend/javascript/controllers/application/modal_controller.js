import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "body"];

  connect() {
    this.modal = document.getElementById("modal");
    this.wrapper = document.getElementById("modal-wrapper");
    this.body = document.getElementById("modal-block");
    this.agreement = document.getElementById("agreement");
    this.password = document.getElementById("password");
  }

  open() {
    this.stopScrollBody();

    setTimeout(() => {
      this.modal.classList.add("open");
      setTimeout(() => {
        this.wrapper.classList.add("open");
      }, 200);
    }, 100);
  }

  openAgreement(event) {
    event.preventDefault();
    this.body.innerHTML = this.agreement.innerHTML;
    this.open();
  }

  openTier() {
    this.stopScrollBody();

    this.modalTarget.classList.add("open");
  }

  openPassword() {
    this.body.innerHTML = this.password.innerHTML;
    this.open();
  }

  close() {
    this.startScrollBody();

    setTimeout(() => {
      this.modalTarget.classList.remove("open");
      setTimeout(() => {
        this.element.classList.remove("open");
        if (this.hasBodyTarget) this.bodyTarget.innerHTML = "";
      }, 550);
    }, 100);
  }

  closeModal(event) {
    if (event.target === event.currentTarget) this.close();
  }

  stopScrollBody() {
    document.body.classList.add("overflow-hidden");
  }

  startScrollBody() {
    document.body.classList.remove("overflow-hidden");
  }
}
