import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["spinner", "error", "countdown"];
  static values = {
    botUrl: { type: String, default: "" },
    countdown: { type: Number, default: 15 },
    endTime: { type: Number, default: 15000 },
  };

  connect() {
    this.mainTimeout = setTimeout(() => {
      this.fetchUserChecker(2000);
    }, 2000);
  }

  disconnect() {
    clearTimeout(this.mainTimeout);
  }

  fetchUserChecker(retryDelay = null) {
    fetch("/user-checker")
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return response.json();
      })
      .then((data) => {
        if (data.started) {
          window.location.href = "/";
        } else {
          this.retryOrRedirect(retryDelay);
        }
      })
      .catch((error) => {
        console.log("Error during authentication:", error);
        this.retryOrRedirect(retryDelay);
      });
  }

  retryOrRedirect(retryDelay) {
    if (retryDelay) {
      setTimeout(() => {
        this.fetchUserChecker();
      }, retryDelay);
    } else {
      this.redirectToBot();
    }
  }

  redirectToBot() {
    let seconds = this.countdownValue;

    this.countdownTarget.textContent = seconds;
    this.spinnerTarget.classList.add("hidden");
    this.errorTarget.classList.remove("hidden");

    const timer = setInterval(() => {
      seconds--;
      this.countdownTarget.textContent = seconds;
      if (seconds <= 0) clearInterval(timer);
    }, 1000);

    setTimeout(() => {
      window.location.href = this.botUrlValue;
    }, this.endTimeValue);
  }
}
