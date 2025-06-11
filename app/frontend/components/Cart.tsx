import React, { useState, useEffect, useMemo } from "react"
import iconsUrl from '../images/icons.svg?url';
import NoticePortal from "./NoticePortal";
import CartItem from "./CartItem";

type CartItem = {
    id: number
    name: string
    price: number
    quantity: number
    image_url: string
    product_path: string
}

export default function Cart({ items, cartId }: { items: CartItem[]; cartId: number }) {
    const [cart, setCart] = useState(items)
    const [notice, setNotice] = useState<string | null>(null);

    const updateQuantity = async (id: number, direction: 'up' | 'down') => {
        const params = new URLSearchParams()
        params.append(direction, 'true')

        const response = await fetch(`/cart_items/${id}`, {
            method: 'PATCH',
            headers: {
                'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '',
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
            },
            body: params.toString(),
        })

        if (response) {
            const data = await response.json()
            if (data.success) {
                const updatedItem = data.cart_item
                setCart(prev =>
                    updatedItem.quantity > 0
                        ? prev.map(item => item.id === updatedItem.id ? { ...item, quantity: updatedItem.quantity } : item)
                        : prev.filter(item => item.id !== updatedItem.id)
                )
            } else {
                setNotice(data.errors || "Ошибка обновления");
            }
        } else {
            setNotice("Ошибка обновления");
        }
    }

    async function handleClearCart(cartId: number) {
        const response = await fetch(`/carts/${cartId}`, {
            method: "DELETE",
            headers: {
                "X-CSRF-Token": (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '',
                "Accept": "application/json"
            }
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
        const totalPrice = cart.reduce((sum, item) => sum + item.price * item.quantity, 0)
        const useDelivery = cart.length === 1 && cart[0].quantity === 1
        window.sharedCartInfo = { useDelivery, totalPrice }
        if (cart.length === 0) {
            const form = document.getElementById('user-form');
            if (form) form.classList.add('hidden');
        }
        window.dispatchEvent(new CustomEvent("cart:updated"))
    }, [cart])

    return cart.length === 0 ? (
        <div className="no-items-wrapper">
            <div className="w-full">
                <div className="flex justify-center text-gray-no-active w-full mb-1">
                    <svg className="pointer-events-none" style={{ fill: "currentColor", width: 40, height: 40 }}>
                        <use href={`${iconsUrl}#cart-empty`} />
                    </svg>
                </div>
                <div className="no-items-title">Корзина пуста</div>
                <a className="block btn btn-secondary btn-big text-center" href="/">Вернуться в каталог</a>
            </div>
        </div>
    ) : (
        <div className="main-block mb-5">
            {notice && (
                <NoticePortal message={notice} type="danger" onClose={() => setNotice(null)} />
            )}
            <div className="cart-items" id="cart_items">
                <div className="flex justify-between items-center mb-3">
                    <div className="font-semibold">Товаров: {totalQuantity}</div>
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

                {cart.map(item => (
                    <CartItem key={item.id} item={item} onUpdateQuantity={updateQuantity} />
                ))}
            </div>
        </div>
    )
}
