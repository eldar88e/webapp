import React, { useState, useEffect, useMemo } from "react"
import iconsUrl from '../images/icons.svg?url';
import NoticePortal from "./NoticePortal";

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

    useEffect(() => {
        if (!notice) return;
        const timeout = setTimeout(() => setNotice(null), 5000);
        return () => clearTimeout(timeout);
    }, [notice]);

    const totalQuantity = useMemo(
        () => cart.reduce((sum, item) => sum + item.quantity, 0),
        [cart]
    )

    useEffect(() => {
        if (totalQuantity === 0) {
            window.location.reload()
        }
    }, [totalQuantity])

    useEffect(() => {
        const totalPrice = cart.reduce((sum, item) => sum + item.price * item.quantity, 0)
        const useDelivery = cart.length === 1 && cart[0].quantity === 1
        window.sharedCartInfo = { useDelivery, totalPrice }
        window.dispatchEvent(new CustomEvent("cart:updated"))
    }, [cart])

    return (
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
                    <div className="font-semibold">Товаров: {totalQuantity}</div>
                    <button
                        className="btn-clear-cart"
                        onClick={async () => {
                            const response = await fetch(`/carts/${cartId}`, {
                                method: "DELETE",
                                headers: {
                                    "X-CSRF-Token": (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content || '',
                                    "Accept": "application/json"
                                }
                            })

                            if (response.ok) {
                                window.location.reload()
                            } else {
                                console.error("Ошибка при очистке корзины")
                            }
                        }}
                    >
                        <div className="flex items-center gap-1">
                            Очистить корзину
                            <svg width={16} height={16} fill="currentColor">
                                <use href={`${iconsUrl}#trash`} />
                            </svg>
                        </div>
                    </button>
                </div>

                {cart.map(item => (
                    <div key={item.id} className="flex justify-between items-center mb-2">
                        <div className="flex items-center gap-4">
                            <div className="bg-gray-100 w-18 h-18 rounded-lg overflow-hidden flex items-center justify-center">
                                {item.image_url ? (
                                    <img src={item.image_url} alt={item.name} width={72} height={72} />
                                ) : (
                                    <svg width={32} height={32} style={{ color: "#48C928" }} fill="currentColor">
                                        <use href={`${iconsUrl}#no-image`} />
                                    </svg>
                                )}
                            </div>
                            <div className="">
                                <a href={item.product_path}>{item.name}</a>
                                <div className="cart-item-price">{item.price}₽/шт</div>
                            </div>
                        </div>
                        <div className="flex items-center gap-1 rounded-lg" style={{ backgroundColor: '#F0F0F0' }}>
                            <button onClick={() => updateQuantity(item.id, 'down')} className="buy-btn">
                                <div className="minus-ico"></div>
                            </button>
                            <div className="text-center min-w-10">
                                <div className="count">{item.quantity} шт</div>
                                <div className="price">{item.quantity * item.price}₽</div>
                            </div>
                            <button onClick={() => updateQuantity(item.id, 'up')} className="buy-btn">
                                <div className="plus-ico"></div>
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}
