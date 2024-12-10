import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  leftAction() {
    leftModal();
    this.toTop();
    openModal();
  }

  rightAction() {
    rightModal();
    this.toTop();
    openModal();
  }

  mainPage() {
    closeModal();
    this.toTop();
  }

  toTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
}
