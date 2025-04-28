import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        words: { type: Array, default: ["Витамин C", "Витамин D"] }
    }

    connect() {
        this.currentWordIndex = 0
        this.currentCharIndex = 0
        this.typing = true
        this.cursorVisible = true
        this.startTyping()
        this.toggleCursor()
    }

    startTyping() {
        const word = this.wordsValue[this.currentWordIndex].substring(0, 33);

        if (this.typing) {
            if (this.currentCharIndex <= word.length) {
                this.updateText(word.substring(0, this.currentCharIndex))
                this.currentCharIndex++
                setTimeout(() => this.startTyping(), 150)
            } else {
                this.typing = false
                setTimeout(() => this.startTyping(), 10)
            }
        } else {
            if (this.currentCharIndex >= 0) {
                this.updateText(word.substring(0, this.currentCharIndex))
                this.currentCharIndex--
                setTimeout(() => this.startTyping(), 150)
            } else {
                this.typing = true
                this.currentWordIndex = (this.currentWordIndex + 1) % this.wordsValue.length
                setTimeout(() => this.startTyping(), 10)
            }
        }
    }

    updateText(text) {
        this.element.placeholder = this.cursorVisible ? `${text}|` : text
    }

    toggleCursor() {
        this.cursorVisible = !this.cursorVisible
        setTimeout(() => {
            const currentText = this.element.placeholder.replace(/\|$/, '')
            this.updateText(currentText)
            this.toggleCursor()
        }, 300)
    }
}
