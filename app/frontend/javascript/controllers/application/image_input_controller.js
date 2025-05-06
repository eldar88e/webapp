import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["preview"]

    connect() {
        const input = document.getElementById("review_photos");
        const preview = this.previewTarget;

        input.addEventListener("change", function () {
            preview.innerHTML = "";

            Array.from(input.files).forEach(file => {
                if (!file.type.startsWith("image/")) return;

                const reader = new FileReader();
                reader.onload = e => {
                    const img = document.createElement("img");
                    img.src = e.target.result;
                    img.classList.add("w-18", "h-18", "object-cover", "rounded-xl");
                    preview.appendChild(img);
                };
                reader.readAsDataURL(file);
            });
        });
    }
}
