import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  openCart() {
    setTimeout(() => {
      Turbo.visit("/carts");
    }, 100)
  }
}
