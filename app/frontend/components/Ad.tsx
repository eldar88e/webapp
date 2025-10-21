import React, { useEffect, useState, useRef } from "react";

export default function Ad({ item }: { item: String }) {
  const [visible, setVisible] = useState(false);
  const adRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const handleScroll = () => {
      if (!adRef.current) return;

      const height = adRef.current.offsetHeight;
      const threshold = height + 10; // высота блока + 10px
      const scrollTop = window.scrollY || document.documentElement.scrollTop;

      if (scrollTop > threshold) {
        setVisible(true);
      } else {
        setVisible(false);
      }
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <div
      ref={adRef}
      className={`fixed top-0 left-0 w-full text-white transition-transform duration-500 ease-in-out z-50 ${
        visible ? "translate-y-0" : "-translate-y-full"
      }`}
      style={{ backgroundColor: "#48C928" }}
    >
      <div className="container mx-auto px-5 py-3">{item}</div>
    </div>
  );
}