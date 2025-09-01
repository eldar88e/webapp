import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["list"];

    showChats() {
        this.listTarget.classList.add('open');
    }

    closeChats() {
        this.listTarget.classList.remove('open');
    }
}
