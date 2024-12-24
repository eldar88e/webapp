import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  toggle() {
    this.menuTarget.classList.toggle("hidden");
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden");
    }
  }

  update(event) {
    event.preventDefault(); // Отменить переход по ссылке
    const selectedText = event.target.textContent.trim(); // Текст выбранного пункта
    this.element.querySelector('button').textContent = selectedText; // Обновляем текст кнопки
    this.menuTarget.classList.add("hidden"); // Скрыть меню
  }
}
