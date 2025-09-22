import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["startDate", "endDate"];

  connect() {
    if (this.hasStartDateTarget && !this.startDateTarget.datepicker) {
      this.startPicker = new Datepicker(this.startDateTarget, {
        autohide: true,
        format: "yyyy-mm-dd",
      });
    }

    if (this.hasEndDateTarget && !this.endDateTarget.datepicker) {
      this.endPicker = new Datepicker(this.endDateTarget, {
        autohide: true,
        format: "yyyy-mm-dd",
      });
    }
  }
}
