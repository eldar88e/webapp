import React, { useEffect, useState, useRef } from "react";

export default function Ad({ item, url }: { item: string, url: string }) {
  const [visible, setVisible] = useState(false);
  const adRef = useRef<HTMLDivElement | null>(null);

  if (!item || !url) return null;

  useEffect(() => {
    let ticking = false;

    const handleScroll = () => {
      if (!adRef.current) return;
      if (ticking) return;

      window.requestAnimationFrame(() => {
        const height = adRef.current!.offsetHeight;
        const threshold = height + 10;
        const scrollTop = window.scrollY || document.documentElement.scrollTop;

        setVisible(scrollTop > threshold);
        ticking = false;
      });

      ticking = true;
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <a href={url} target="_blank" rel="noopener noreferrer">
      <div
        ref={adRef}
        className={`fixed top-0 left-0 w-full text-white transition-transform transition-opacity duration-500 ease-in-out z-50 ${
          visible ? "translate-y-0 opacity-100" : "-translate-y-full opacity-0"
        }`}
        style={{ backgroundColor: "#48C928" }}
      >
        <div
          className="text-xs container mx-auto px-3 py-2"
          style={{ lineHeight: "1.2" }}
        >{item}</div>
      </div>
    </a>
  );
}
