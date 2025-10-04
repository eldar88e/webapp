import React, { useState, useEffect, useMemo } from "react";
import iconsUrl from "../images/icons.svg?url";
import NoticePortal from "./NoticePortal";
import CartItem from "./CartItem";

type CartLine = {
  id: number;
  name: string;
  price: number;
  quantity: number;
  image_url: string;
  product_path: string;
};

export default function Cart({
  items,
  cartId,
}: {
  items: CartLine[];
  cartId: number;
}) {
  const [cart, setCart] = useState(items);
  const [notice, setNotice] = useState<string | null>(null);

  const updateQuantity = async (id: number, direction: "up" | "down") => {
    const params = new URLSearchParams();
    params.append(direction, "true");

    const response = await fetch(`/cart_items/${id}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token":
          (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)
            ?.content || "",
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "application/json",
      },
      body: params.toString(),
    });

    if (response) {
      const data = await response.json();
      if (data.success) {
        const updatedItem = data.cart_item;
        setCart((prev) =>
          updatedItem.quantity > 0
            ? prev.map((item) =>
                item.id === updatedItem.id
                  ? { ...item, quantity: updatedItem.quantity }
                  : item,
              )
            : prev.filter((item) => item.id !== updatedItem.id),
        );
      } else {
        setNotice(data.errors || "Ошибка обновления");
      }
    } else {
      setNotice("Ошибка обновления");
    }
  };

  async function handleClearCart(cartId: number) {
    const response = await fetch(`/carts/${cartId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token":
          (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)
            ?.content || "",
        Accept: "application/json",
      },
    });

    response.ok ? setCart([]) : setNotice("Ошибка при очистке корзины");
  }

  useEffect(() => {
    if (!notice) return;

    const timeout = setTimeout(() => setNotice(null), 5000);
    return () => clearTimeout(timeout);
  }, [notice]);

  const totalQuantity = useMemo(() => {
    return cart.reduce((sum, item) => sum + item.quantity, 0);
  }, [cart]);

  useEffect(() => {
    const totalPrice = cart.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
    const useDelivery = cart.length === 1 && cart[0].quantity === 1;
    window.sharedCartInfo = { useDelivery, totalPrice };
    if (cart.length === 0) {
      const form = document.getElementById("user-form");
      if (form) form.classList.add("hidden");
    }
    window.dispatchEvent(new CustomEvent("cart:updated"));
  }, [cart]);

  return cart.length === 0 ? (
    <div className="no-items-wrapper">
      <div className="w-full">
        <div className="flex justify-center text-gray-no-active w-full mb-1">
          <svg
            className="pointer-events-none"
            style={{ fill: "currentColor", width: 40, height: 40 }}
          >
            <use href={`${iconsUrl}#cart-empty`} />
          </svg>
        </div>
        <div className="no-items-title">Корзина пуста</div>
        <a className="block btn btn-secondary btn-big text-center" href="/">
          Вернуться в каталог
        </a>
      </div>
    </div>
  ) : (
    <>
      <div className="main-block mb-5">
        {notice && (
          <NoticePortal
            message={notice}
            type="danger"
            onClose={() => setNotice(null)}
          />
        )}
        <div className="cart-items" id="cart_items">
          <div className="flex justify-between items-center mb-3">
            <div className="font-semibold">
              Товаров: <span id="cart-items-count">{totalQuantity}</span>
            </div>
            <button
              className="btn-clear-cart"
              onClick={() => handleClearCart(cartId)}
            >
              <div className="flex items-center gap-1 active:text-red-600">
                Очистить корзину
                <svg width={16} height={16} fill="currentColor">
                  <use href={`${iconsUrl}#trash`} />
                </svg>
              </div>
            </button>
          </div>

          {cart.map((item) => (
            <CartItem
              key={item.id}
              item={item}
              onUpdateQuantity={updateQuantity}
            />
          ))}
        </div>
      </div>
      {cart.length === 1 && cart[0].quantity === 1 && (
        <div className="relative mb-5 p-5" style={{ backgroundColor: "#48C928", borderRadius: "20px" }}>
          <div className="text-white">
            Добавьте еще 1 позицию и<br/>доставка станет 0₽ вместо 500₽
          </div>
          <div className="absolute overflow-hidden top-0 right-2 w-20 h-20 flex items-center justify-center">
            <div className="pulse-wrapper">
              <span className="pulse-ring"></span>
              <span className="pulse-ring"></span>
              <span className="pulse-ring"></span>
              <div className="bg-white rounded-full p-4 pulse-core">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M16 16L18 18L22 14" stroke="#48C928" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  <path d="M21 9.99999V7.99999C20.9996 7.64927 20.9071 7.3048 20.7315 7.00116C20.556 6.69751 20.3037 6.44536 20 6.26999L13 2.26999C12.696 2.09446 12.3511 2.00204 12 2.00204C11.6489 2.00204 11.304 2.09446 11 2.26999L4 6.26999C3.69626 6.44536 3.44398 6.69751 3.26846 7.00116C3.09294 7.3048 3.00036 7.64927 3 7.99999V16C3.00036 16.3507 3.09294 16.6952 3.26846 16.9988C3.44398 17.3025 3.69626 17.5546 4 17.73L11 21.73C11.304 21.9055 11.6489 21.9979 12 21.9979C12.3511 21.9979 12.696 21.9055 13 21.73L15 20.59" stroke="#48C928" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  <path d="M7.5 4.26999L16.5 9.41999" stroke="#48C928" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  <path d="M3.29004 7L12 12L20.71 7" stroke="#48C928" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  <path d="M12 22V12" stroke="#48C928" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
