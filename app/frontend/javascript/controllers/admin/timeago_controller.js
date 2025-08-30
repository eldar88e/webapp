import { Controller } from "@hotwired/stimulus";
import { render, register } from "timeago.js";
import ru from "timeago.js/lib/lang/ru";

register("ru", ru);

export default class extends Controller {
  static values = { locale: { type: String, default: "ru" } };

  connect() {
    const date = new Date(
      this.element.dateTime || this.element.getAttribute("datetime"),
    );
    const now = new Date();
    const diff = now - date;
    const oneDay = 24 * 60 * 60 * 1000;

    if (diff < oneDay) {
      render(this.element, this.localeValue);
    }
  }
}
