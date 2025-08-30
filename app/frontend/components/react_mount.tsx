import React from "react";
import { createRoot } from "react-dom/client";
import Cart from "./Cart.tsx";
import CartSummary from "./CartSummary.tsx";

document.addEventListener("DOMContentLoaded", () => {
  const el = document.getElementById("react-cart");
  if (!el) return;

  const items = JSON.parse(el.dataset.cartItems || "[]");
  const bonus = parseInt(el.dataset.bonus || 0);
  const cartId = parseInt(el.dataset.userCartId);
  const deliveryPrice = parseInt(el.dataset.deliveryPrice || 0);
  const percent = parseInt(el.dataset.percent || 0);
  const bonusThreshold = parseInt(el.dataset.bonusThreshold || 0);

  const root = createRoot(el);
  root.render(<Cart items={items} cartId={cartId} />);

  const summaryEl = document.getElementById("react-cart-summary");
  if (summaryEl) {
    const root = createRoot(summaryEl);
    root.render(
      <CartSummary
        deliveryPrice={deliveryPrice}
        bonus={bonus}
        percent={percent}
        bonusThreshold={bonusThreshold}
      />,
    );
  }
});
