import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  mask() {
    let rawValue = this.element.value.replace(/\D/g, "");
    if (rawValue.startsWith("8")) {
      rawValue = "7" + rawValue.slice(1);
    } else if (!rawValue.startsWith("7") && rawValue.length > 0) {
      rawValue = "7" + rawValue;
    }

    const length = rawValue.length;
    let formattedValue = "";

    if (length > 0) formattedValue += "+7"
    if (length > 1) formattedValue += " (" + rawValue.slice(1, 4);
    if (length > 4) formattedValue += ") " + rawValue.slice(4, 7);
    if (length > 7) formattedValue += " - " + rawValue.slice(7, 9);
    if (length > 9) formattedValue += " - " + rawValue.slice(9, 11);

    this.element.value = formattedValue.substring(0, 22);
  }
}
