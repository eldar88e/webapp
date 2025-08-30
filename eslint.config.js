import js from "@eslint/js";
import ts from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import prettier from "eslint-plugin-prettier";
import importPlugin from "eslint-plugin-import";

/** @type {import('eslint').Linter.FlatConfig[]} */
export default [
    js.configs.recommended,
    {
        files: ["app/frontend/**/*.{js,ts,jsx,tsx}"],
        languageOptions: {
            parser: tsParser,
            ecmaVersion: "latest",
            sourceType: "module",
            globals: {
              fetch: "readonly",
              window: "readonly",
              document: "readonly",
              confirm: "readonly",
              alert: "readonly",
              console: "readonly",
              localStorage: "readonly",
              sessionStorage: "readonly",
              HTMLMetaElement: "readonly",
              URLSearchParams: "readonly",
              FileReader: "readonly",
              IntersectionObserver: "readonly",
              navigator: "readonly",
              CustomEvent: "readonly",
              setTimeout: "readonly",
              setInterval: "readonly",
              clearTimeout: "readonly",
              clearInterval: "readonly",
              HTMLInputElement: "readonly",
              Telegram: "readonly", // for TelegramWebApp
              closeModal: "readonly",
              openModal: "readonly",
              suggestions_cache: "readonly",
              dadata_token: "readonly",
            },
        },
        plugins: {
            "@typescript-eslint": ts,
            react,
            "react-hooks": reactHooks,
            prettier,
            import: importPlugin
        },
        rules: {
            "prettier/prettier": "error",
            "react/react-in-jsx-scope": "off"
        },
        settings: {
            react: {
                version: "detect"
            }
        }
    }
];
