import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.inputs = this.element.querySelectorAll("input")
        this.inputs.forEach(input => {
            input.addEventListener("input", this.toggleLabel.bind(this))
            input.addEventListener("focus", this.toggleLabel.bind(this))
            input.addEventListener("blur", this.toggleLabel.bind(this))
        })
    }

    toggleLabel(event) {
        const inputElement = event.target;
        const labelElement = inputElement.previousElementSibling;

        if (inputElement.value.trim() === "") {
            labelElement.style.visibility = "hidden";
        } else {
            labelElement.style.visibility = "visible";
        }
    }
}