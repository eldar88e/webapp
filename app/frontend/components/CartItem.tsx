import React from "react";
import iconsUrl from "../images/icons.svg?url";

type CartItemProps = {
  item: {
    id: number;
    name: string;
    price: number;
    quantity: number;
    image_url: string;
    product_path: string;
  };
  onUpdateQuantity: (id: number, direction: "up" | "down") => void;
};

export default function CartItem({ item, onUpdateQuantity }: CartItemProps) {
  return (
    <div className="flex justify-between items-center mb-2" id={`cart-item-${item.id}`}>
      <div className="flex items-center gap-4">
        <div className="bg-gray-100 w-18 h-18 rounded-lg overflow-hidden flex items-center justify-center">
          {item.image_url ? (
            <img src={item.image_url} alt={item.name} width={72} height={72} />
          ) : (
            <svg
              width={32}
              height={32}
              style={{ color: "#48C928" }}
              fill="currentColor"
            >
              <use href={`${iconsUrl}#no-image`} />
            </svg>
          )}
        </div>
        <div>
          <a href={item.product_path}>{item.name}</a>
          <div className="cart-item-price">{item.price}₽/шт</div>
        </div>
      </div>
      <div
        className="flex items-center gap-1 rounded-lg"
        style={{ backgroundColor: "#F0F0F0" }}
      >
        <button
          onClick={() => onUpdateQuantity(item.id, "down")}
          className="buy-btn"
        >
          <div className="minus-ico"></div>
        </button>
        <div className="text-center min-w-10">
          <div className="count">{item.quantity} шт</div>
          <div className="price">{item.quantity * item.price}₽</div>
        </div>
        <button
          onClick={() => onUpdateQuantity(item.id, "up")}
          className="buy-btn"
        >
          <div className="plus-ico"></div>
        </button>
      </div>
    </div>
  );
}
