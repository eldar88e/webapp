import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.element.addEventListener('click', (event) => {
            if (event.target === this.element) {
                this.element.classList.add('hidden');
                this.element.classList.remove('flex');
            }
        });
    }

    close(){
        this.element.classList.add('hidden');
        this.element.classList.remove('flex');
    }
}