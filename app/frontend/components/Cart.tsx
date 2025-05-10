import React, { useState, useEffect, useMemo } from "react"

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
                const errors = data.errors;
                const notices = document.getElementById("notices");
                if (!notices) return;

                notices.insertAdjacentHTML('beforeend', `<div data-controller="notices" data-notices-text-value="danger"  class="flex items-center w-full max-w-xs p-2 mb-2 rounded-lg shadow bg-white notices" role="alert">
                                         <div>
                                            <svg class="w-5 h-5 text-red-500" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
                                              <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5Zm3.707 11.793a1 1 0 1 1-1.414 1.414L10 11.414l-2.293 2.293a1 1 0 0 1-1.414-1.414L8.586 10 6.293 7.707a1 1 0 0 1 1.414-1.414L10 8.586l2.293-2.293a1 1 0 0 1 1.414 1.414L11.414 10l2.293 2.293Z"/>
                                            </svg>
                                          </div>
                                          <div class="ms-3 text-sm font-normal">${errors}</div>
                                          <button data-action="click->notices#close" type="button" class="ms-auto -mx-1.5 -my-1.5 rounded-lg p-1.5 inline-flex items-center justify-center h-8 w-8 bg-white focus:text-green-600 close" data-dismiss-target="#toast-danger" aria-label="Close">
                                            <span class="sr-only">Close</span>
                                            <svg class="w-3 h-3" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 14">
                                              <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"/>
                                            </svg>
                                          </button>                                     
                                      </div>`);
            }
        } else {
            console.error("Ошибка обновления")
        }
    }

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
                        <span>Очистить корзину</span>
                    </button>
                </div>

                {cart.map(item => (
                    <div key={item.id} className="flex justify-between items-center mb-2">
                        <div className="flex items-center gap-4">
                            <div className="bg-gray-100 w-18 h-18 rounded-lg overflow-hidden flex items-center justify-center">
                                {item.image_url && (
                                    <img src={item.image_url} alt={item.name} width={72} height={72} />
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
