import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "messages", "attach"];

  connect() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }

  clear(event) {
    if (
      this.inputTarget.value.trim() === "" &&
      this.attachTarget.files.length === 0
    ) {
      event.preventDefault();
      alert("Введите сообщение или прикрепите файл");
      return;
    }

    setTimeout(() => {
      this.inputTarget.value = "";
      this.attachTarget.value = "";
      this.attachTarget.files = null;
      setTimeout(() => {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
      }, 100);
    });
  }
}
