import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "messages", "attach", "reply", "replyPreview", "replyText"];

  connect() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }

  selectReply(event) {
    const button = event.currentTarget;
    const messageId = button.dataset.messageId;
    const messageText = button.dataset.messageText || "Медиа";

    this.replyTarget.value = messageId;
    this.replyTextTarget.textContent = messageText;
    this.replyPreviewTarget.classList.remove("hidden");
    this.inputTarget.focus();
  }

  cancelReply() {
    this.replyTarget.value = "";
    this.replyTextTarget.textContent = "";
    this.replyPreviewTarget.classList.add("hidden");
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
      this.inputTarget.style.height = "auto";
      this.cancelReply();
      setTimeout(() => {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
      }, 100);
    });
  }
}
