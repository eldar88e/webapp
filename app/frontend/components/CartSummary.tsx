import React, { useEffect, useState, useMemo } from "react";

type SharedCartInfo = {
  useDelivery: boolean;
  totalPrice: number;
};

declare global {
  interface Window {
    sharedCartInfo?: SharedCartInfo;
  }
}

export default function CartSummary({
  bonus,
  deliveryPrice,
  percent,
  bonusThreshold,
}: {
  bonus: number;
  deliveryPrice: number;
  percent: number;
  bonusThreshold: number;
}) {
  const [useDelivery, setDelivery] = useState(false);
  const [totalPrice, setTotalPrice] = useState(0);
  const [appliedBonus, setAppliedBonus] = useState(0);

  useEffect(() => {
    const handleUpdate = () => {
      if (window.sharedCartInfo) {
        setDelivery(window.sharedCartInfo.useDelivery);
        setTotalPrice(window.sharedCartInfo.totalPrice);
      }
    };

    window.addEventListener("cart:updated", handleUpdate);
    handleUpdate();

    return () => {
      window.removeEventListener("cart:updated", handleUpdate);
    };
  }, []);

  const deliveryFee = useDelivery ? deliveryPrice : 0;
  const maxApplicableBonus = useMemo(
    () => Math.min(bonus, totalPrice),
    [bonus, totalPrice],
  );
  const applicableBonusSteps = useMemo(
    () => Math.floor(maxApplicableBonus / 100) * 100,
    [maxApplicableBonus],
  );
  const final = totalPrice + deliveryFee - appliedBonus;
  const bonusDisabled =
    totalPrice < bonusThreshold || applicableBonusSteps === 0;
  const upBonus = Math.floor((totalPrice * percent) / 100 / 50) * 50;

  return (
    <div className="cart-summary mt-6">
      {!bonusDisabled && (
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
            />
          </div>
          {bonus < 100 && (
            <p className="text-xs text-gray-500">
              У&nbsp;вас недостаточно бонусов (нужно ≥ 100)
            </p>
          )}
        </div>
      )}

      <div className="mb-5">
        <div className="flex justify-between">
          <div className="price-title">Товары:</div>
          <div className="font-medium" id="cart-total-price">
            {totalPrice}₽
          </div>
        </div>
        <div className="flex justify-between">
          <div className="price-title">Скидка:</div>
          <div className="font-medium green">{-appliedBonus}₽</div>
        </div>
        <div className="flex justify-between">
          <div className="price-title">Доставка:</div>
          <div className="font-medium" id="cart-delivery-price">
            {deliveryFee}₽
          </div>
        </div>
        <div className="flex justify-between">
          <div className="price-title">Итоговая стоимость:</div>
          <div className="end-price" id="cart-final-price">
            {final}₽
          </div>
        </div>
        <div className="min-h-5 w-full">
          {totalPrice > bonusThreshold ? (
            appliedBonus === 0 && percent > 0 && (
              <div className="bonus-user-up">
                Начислим кэшбек после оплаты:
                <span className="price">{upBonus}₽</span>
              </div>
            )
          ) : (
            <>
              <div className="w-full rounded-lg h-1 mb-2" style={{ backgroundColor: "#F0F0F0" }}>
                <div className="h-full rounded-lg" style={{ width: `${(totalPrice / bonusThreshold) * 100}%`, backgroundColor: "#48C928" }}>
                </div>
              </div>
              <div className="bonus-notice-text">
                Добавьте товаров еще на {bonusThreshold - totalPrice}₽, чтобы получить бонусы
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
