import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["delivery", "itemQuantity"];

    connect() {
        this.toggleDeliveryVisibility();
    }

    toggleDeliveryVisibility() {
        const itemsCount = this.itemQuantityTargets.length;
        const shouldHideDelivery = itemsCount > 1 || this.getQuantityForSingleItem() > 1;

        if (shouldHideDelivery) {
            this.deliveryTarget.classList.remove('hidden');
        } else {
            this.deliveryTarget.classList.add('hidden');
        }
    }

    getQuantityForSingleItem() {
        const firstItemQuantityElement = this.itemQuantityTargets[0].querySelector(".num");
        return firstItemQuantityElement ? parseInt(firstItemQuantityElement.textContent) : 0;
    }
}