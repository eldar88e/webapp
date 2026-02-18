import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "input", "messages", "attach", "reply",
    "replyPreview", "replyText", "replyMediaWrap", "replyMediaName",
    "attachPreview", "attachMediaWrap", "attachName"
  ];

  connect() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }

  selectReply(event) {
    const button = event.currentTarget;
    const messageId = button.dataset.messageId;
    const messageText = button.dataset.messageText || "Медиа";
    const mediaUrl = button.dataset.messageMediaUrl;
    const mediaName = button.dataset.messageMediaName;
    const mediaType = button.dataset.messageMediaType;

    this.replyTarget.value = messageId;
    this.replyTextTarget.textContent = messageText;

    if (mediaUrl) {
      this.replyMediaWrapTarget.innerHTML = this.buildMediaPreview(mediaUrl, mediaType);
      this.replyMediaWrapTarget.classList.remove("hidden");
      this.replyMediaNameTarget.textContent = mediaName || "";
      this.replyMediaNameTarget.classList.toggle("hidden", !mediaName);
    } else {
      this.replyMediaWrapTarget.innerHTML = "";
      this.replyMediaWrapTarget.classList.add("hidden");
      this.replyMediaNameTarget.classList.add("hidden");
    }

    this.replyPreviewTarget.classList.remove("hidden");
    this.inputTarget.focus();
  }

  cancelReply() {
    this.replyTarget.value = "";
    this.replyTextTarget.textContent = "";
    this.replyMediaWrapTarget.innerHTML = "";
    this.replyMediaWrapTarget.classList.add("hidden");
    this.replyMediaNameTarget.textContent = "";
    this.replyMediaNameTarget.classList.add("hidden");
    this.replyPreviewTarget.classList.add("hidden");
  }

  selectAttach() {
    const file = this.attachTarget.files[0];
    if (!file) {
      this.cancelAttach();
      return;
    }

    this.attachNameTarget.textContent = file.name;
    const url = URL.createObjectURL(file);

    if (file.type.startsWith("image/")) {
      this.attachMediaWrapTarget.innerHTML =
        `<img src="${url}" class="w-10 h-10 object-cover" />`;
      this.attachMediaWrapTarget.classList.remove("hidden");
    } else if (file.type.startsWith("video/")) {
      this.attachMediaWrapTarget.innerHTML =
        `<video src="${url}" class="w-10 h-10 object-cover" muted preload="metadata"></video>`;
      this.attachMediaWrapTarget.classList.remove("hidden");
    } else {
      this.attachMediaWrapTarget.innerHTML = "";
      this.attachMediaWrapTarget.classList.add("hidden");
    }

    this.attachPreviewTarget.classList.remove("hidden");
  }

  cancelAttach() {
    this.attachTarget.value = "";
    this.revokeAttachUrls();
    this.attachMediaWrapTarget.innerHTML = "";
    this.attachMediaWrapTarget.classList.add("hidden");
    this.attachNameTarget.textContent = "";
    this.attachPreviewTarget.classList.add("hidden");
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
      this.cancelAttach();
      setTimeout(() => {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
      }, 100);
    });
  }

  buildMediaPreview(url, type) {
    if (type && type.startsWith("image")) {
      return `<img src="${url}" class="w-10 h-10 object-cover" />`;
    } else if (type && type.startsWith("video")) {
      return `<video src="${url}" class="w-10 h-10 object-cover" muted preload="metadata"></video>`;
    }
    return "";
  }

  revokeAttachUrls() {
    const media = this.attachMediaWrapTarget.querySelector("img, video");
    if (media && media.src.startsWith("blob:")) {
      URL.revokeObjectURL(media.src);
    }
  }
}
