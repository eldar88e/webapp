import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.sortable = new Sortable(this.element, {
      group: "kanban",
      animation: 150,
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const taskId = event.item.dataset.id
    const newStage = event.to.dataset.stage
    const newPosition = event.newIndex

    fetch(`/admin/tasks/${taskId}/move`, {
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
