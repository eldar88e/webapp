import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.startTimer();
    }

    startTimer() {
        this.timer = setInterval(() => {
            this.fadeOutAndRemove();
        }, 5000)
    }

    fadeOutAndRemove() {
        this.element.classList.add("fade-out");
        setTimeout(() => {
            this.element.remove();
        }, 1000);
    }

    close() {
        clearInterval(this.timer);
        this.fadeOutAndRemove();
    }
}