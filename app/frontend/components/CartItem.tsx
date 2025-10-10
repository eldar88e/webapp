/* eslint-disable no-unused-vars */

import React from "react";
import SvgIcon from "./ui/SvgIcon";

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
    <div
      className="flex justify-between items-center mb-2"
      id={`cart-item-${item.id}`}
    >
      <div className="flex items-center gap-4">
        <div className="bg-gray-100 w-18 h-18 min-w-18 rounded-lg overflow-hidden flex items-center justify-center">
          {item.image_url ? (
            <img
              src={item.image_url}
              alt={item.name}
              width={72}
              height={72}
              loading="lazy"
            />
          ) : (
            <SvgIcon name="no-image" width={42} className="text-[#48C928]" />
          )}
        </div>
        <div>
          <a href={item.product_path} className="cart-item-name">
            {item.name}
          </a>
          <div className="cart-item-price">{item.price}₽/шт</div>
        </div>
      </div>
      <div
        className="flex items-center gap-1 rounded-lg"
        style={{ backgroundColor: "#F0F0F0" }}
      >
        <button
          type="button"
          onClick={() => onUpdateQuantity(item.id, "down")}
          className="buy-btn"
        >
          <div className="minus-ico" />
        </button>
        <div className="text-center min-w-10">
          <div className="count">{item.quantity} шт</div>
          <div className="price">{item.quantity * item.price}₽</div>
        </div>
        <button
          type="button"
          onClick={() => onUpdateQuantity(item.id, "up")}
          className="buy-btn"
        >
          <div className="plus-ico" />
        </button>
      </div>
    </div>
  );
}
