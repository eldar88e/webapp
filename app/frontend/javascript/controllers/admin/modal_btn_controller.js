import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    open() {
        const modal = document.getElementById('modal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
}