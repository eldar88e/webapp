import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "messages"];

    connect() {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
    }

    clear(event) {
      // event.preventDefault();
      // if (this.inputTarget.value.trim() === '') return;
      //
      // event.currentTarget.requestSubmit();
      // this.element.querySelector('form').requestSubmit();

      setTimeout(() => {
        this.inputTarget.value = '';
        setTimeout(() => {
          this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
        }, 100);
      })
    }
}
