import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["startDate", "endDate"];
  static values = {
    min: { type: String, default: "2024-12-01" },
    max: { type: String, default: null },
  }

  connect() {
    const minDate = this.minValue ? new Date(this.minValue) : null;
    const maxDate = this.maxValue ? new Date(this.maxValue) : new Date();

    if (this.hasStartDateTarget && !this.startDateTarget.datepicker) {
      this.startPicker = new Datepicker(this.startDateTarget, {
        autohide: true,
        format: "yyyy-mm-dd",
        minDate: minDate,
        maxDate: maxDate,
      });
    }

    if (this.hasEndDateTarget && !this.endDateTarget.datepicker) {
      this.endPicker = new Datepicker(this.endDateTarget, {
        autohide: true,
        format: "yyyy-mm-dd",
        minDate: minDate,
        maxDate: maxDate,
      });
    }
  }
}
