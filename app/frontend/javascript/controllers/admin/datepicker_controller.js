import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["startDate", "endDate"];

  connect() {
    console.log("datepicker connected");
  }
}
