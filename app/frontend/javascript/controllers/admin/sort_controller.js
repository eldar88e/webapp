import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["table"];

  connect() {
    this.currentColumn = null;
    this.currentDirection = "asc";
  }

  sort(event) {
    const header = event.currentTarget;
    const columnIndex = header.cellIndex;
    const tbody = this.tableTarget.querySelector("tbody");
    const rows = Array.from(tbody.querySelectorAll("tr.item, tbody > tr"));

    if (this.currentColumn === columnIndex) {
      this.currentDirection = this.currentDirection === "asc" ? "desc" : "asc";
    } else {
      this.currentColumn = columnIndex;
      this.currentDirection = "asc";
    }

    rows.sort((ra, rb) => {
      const ca = this.getCellAtColumn(ra, columnIndex);
      const cb = this.getCellAtColumn(rb, columnIndex);

      const aText = (ca?.innerText || "").trim();
      const bText = (cb?.innerText || "").trim();

      const aVal = this.parseValue(aText);
      const bVal = this.parseValue(bText);

      const aNil = aVal === null;
      const bNil = bVal === null;
      if (aNil && bNil) return 0;
      if (aNil) return 1;
      if (bNil) return -1;

      if (aVal < bVal) return this.currentDirection === "asc" ? -1 : 1;
      if (aVal > bVal) return this.currentDirection === "asc" ? 1 : -1;
      return 0;
    });

    rows.forEach((r) => tbody.appendChild(r));
  }

  getCellAtColumn(row, colIndex) {
    let acc = 0;
    for (const cell of row.cells) {
      const span = parseInt(cell.getAttribute("colspan") || "1", 10);
      if (acc + span > colIndex) return cell;
      acc += span;
    }
    return null;
  }

  // Нормализуем значения: "13 шт.", "1 234,56 ₽", "—", "-29.2 %"
  parseValue(text) {
    if (!text) return null;

    const dash = text.replace(/\s+/g, "").replace(/\u2014/g, "-"); // em-dash
    if (dash === "—" || dash === "-" || /^(—|—|—)$/.test(text)) return null;

    let cleaned = text
      .replace(/\u00A0/g, " ")
      .replace(/\s+/g, "")
      .replace(",", ".")
      .replace(/[^\d.-]/g, "");

    if (cleaned === "" || isNaN(cleaned)) {
      const s = text.toLowerCase().trim();
      return s === "" ? null : s;
    }
    return parseFloat(cleaned);
  }
}
