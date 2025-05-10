import React, { useEffect, useState, useMemo } from "react"

type SharedCartInfo = {
    useDelivery: boolean
    totalPrice: number
}

declare global {
    interface Window {
        sharedCartInfo?: SharedCartInfo
    }
}

export default function CartSummary({ bonus, deliveryPrice, percent }: { bonus: number; deliveryPrice: number; percent: number }) {
    const [useDelivery, setDelivery] = useState(false)
    const [totalPrice, setTotalPrice] = useState(0)
    const [appliedBonus, setAppliedBonus] = useState(0)

    useEffect(() => {
        const handleUpdate = () => {
            if (window.sharedCartInfo) {
                setDelivery(window.sharedCartInfo.useDelivery)
                setTotalPrice(window.sharedCartInfo.totalPrice)
            }
        }

        window.addEventListener("cart:updated", handleUpdate)
        handleUpdate()

        return () => {
            window.removeEventListener("cart:updated", handleUpdate)
        }
    }, [])

    const deliveryFee = useDelivery ? deliveryPrice : 0
    const maxApplicableBonus = useMemo(
        () => Math.min(bonus, totalPrice),
        [bonus, totalPrice]
    )
    const applicableBonusSteps = useMemo(
        () => Math.floor(maxApplicableBonus / 100) * 100,
        [maxApplicableBonus]
    )
    const final = totalPrice + deliveryFee - appliedBonus
    const bonusDisabled = totalPrice < 2000 || applicableBonusSteps === 0
    const upBonus = Math.floor((totalPrice * percent / 100) / 50) * 50;

    return (
        <div className="cart-summary mt-6">
            <div className="main-block mb-5 bonus-block-cart">
                <h3>Используйте бонусы</h3>
                <div className="bonus-ranges">
                    <div>0</div>
                    <div>{applicableBonusSteps}</div>
                </div>
                <div className="px-3">
                    <input
                        className="bonus-range"
                        name="user[bonus]"
                        type="range"
                        min={0}
                        max={applicableBonusSteps}
                        step={100}
                        value={appliedBonus}
                        onChange={(e) => setAppliedBonus(parseInt(e.target.value, 10))}
                        disabled={bonusDisabled}
                    />
                </div>
                {totalPrice < 2000 && (
                    <p className="text-xs text-gray-500">
                        Бонусы можно применить при сумме заказа от&nbsp;2000₽
                    </p>
                )}
                {bonus < 100 && (
                    <p className="text-xs text-gray-500">
                        У&nbsp;вас недостаточно бонусов (нужно ≥ 100)
                    </p>
                )}
            </div>

            <div className="mb-5">
                <div className="flex justify-between">
                    <div className="price-title">Товары:</div>
                    <div className="font-medium">{totalPrice}₽</div>
                </div>
                <div className="flex justify-between">
                    <div className="price-title">Скидка:</div>
                    <div className="font-medium green">{-appliedBonus}₽</div>
                </div>
                <div className="flex justify-between">
                    <div className="price-title">Доставка:</div>
                    <div className="font-medium">{deliveryFee}₽</div>
                </div>
                <div className="flex justify-between">
                    <div className="price-title">Итоговая стоимость:</div>
                    <div className="end-price">{final}₽</div>
                </div>
                <div style={{ height: '20px', width: '100%' }}>
                    {appliedBonus === 0 && percent > 0 && (
                        <div className="bonus-user-up">Начислим кэшбек после оплаты:<span className="price">{upBonus}₽</span></div>
                    )}
                </div>
            </div>
        </div>
    )
}
