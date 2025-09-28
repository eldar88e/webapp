import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.sortable = new Sortable(this.element, {
      group: "kanban",          // позволяет таскать между колонками
      animation: 150,
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const taskId = event.item.dataset.id
    const newStage = event.to.dataset.stage
    const newPosition = event.newIndex

    console.log(newPosition);

    fetch(`/admin/tasks/${taskId}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        task: { stage: newStage, position: newPosition }
      })
    })
  }
}
