import React from "react";

type NoticeProps = {
  message: string;
  type?: "danger" | "success" | "info";
  onClose?: () => void;
};

export default function Notice({ message, type, onClose }: NoticeProps) {
  return (
    <div
      className={`flex items-center w-full max-w-xs p-2 mb-2 rounded-lg shadow bg-white notices`}
      role="alert"
    >
      <div>
        <svg
          className="w-5 h-5 text-red-500"
          aria-hidden="true"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5Zm3.707 11.793a1 1 0 1 1-1.414 1.414L10 11.414l-2.293 2.293a1 1 0 0 1-1.414-1.414L8.586 10 6.293 7.707a1 1 0 0 1 1.414-1.414L10 8.586l2.293-2.293a1 1 0 0 1 1.414 1.414L11.414 10l2.293 2.293Z" />
        </svg>
      </div>
      <div className="ms-3 text-sm font-normal">{message}</div>
      {onClose && (
        <button
          type="button"
          className="ms-auto -mx-1.5 -my-1.5 rounded-lg p-1.5 inline-flex items-center justify-center h-8 w-8 bg-white focus:text-green-600 close"
          aria-label="Close"
          onClick={onClose}
        >
          <span className="sr-only">Close</span>
          <svg
            className="w-3 h-3"
            aria-hidden="true"
            fill="none"
            viewBox="0 0 14 14"
          >
            <path
              stroke="currentColor"
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"
            />
          </svg>
        </button>
      )}
    </div>
  );
}
