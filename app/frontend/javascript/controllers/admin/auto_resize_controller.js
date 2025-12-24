import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.lineHeight = parseFloat(
      window.getComputedStyle(this.element).lineHeight,
    );
    this.maxLines = 5;
    this.maxHeight = this.lineHeight * this.maxLines;
  }

  resize() {
    const textarea = this.element;

    textarea.style.height = "auto";

    if (textarea.scrollHeight > this.maxHeight) {
      textarea.style.height = `${this.maxHeight}px`;
      textarea.style.overflowY = "auto";
    } else {
      textarea.style.height = `${textarea.scrollHeight}px`;
      textarea.style.overflowY = "hidden";
    }
  }
}
