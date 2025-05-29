import React from "react";
import { createPortal } from "react-dom";
import Notice from "./Notice";

type NoticePortalProps = {
    message: string;
    type?: "danger" | "success" | "info";
    onClose?: () => void;
};

export default function NoticePortal(props: NoticePortalProps) {
    const noticesFrame = document.getElementById("notices");
    if (!noticesFrame) return null;
    return createPortal(
        <Notice {...props} />,
        noticesFrame
    );
}