import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview"];

  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("change", (event) =>
        this.previewFiles(event),
      );
    }
  }

  previewFiles(event) {
    const files = event.target.files;
    this.previewTarget
      .querySelectorAll("img.new")
      .forEach((img) => img.remove());

    Array.from(files).forEach((file) => {
      if (!file.type.startsWith("image/")) return;

      const reader = new FileReader();
      reader.onload = (e) => {
        const img = document.createElement("img");
        img.src = e.target.result;
        img.className = "w-18 h-18 object-cover rounded-xl new";
        this.previewTarget.appendChild(img);
      };
      reader.readAsDataURL(file);
    });
  }
}
