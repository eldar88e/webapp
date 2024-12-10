import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suggestions", "address", "post_code"];

  search(event) {
    const query = event.target.value.trim();

    if (!query) {
      this.suggestionsTarget.textContent = '';
      this.suggestionsTarget.style = "display: none;"
      return;
    }

    let url   = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address";
    let token = "bbec7e427009a796a2ef0a4d9bd8315f3db7fa87";

    let options = {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Token " + token
      },
      body: JSON.stringify({query: event.target.value})
    };

    fetch(url, options)
        .then(response => {
          if (!response.ok) { throw new Error(`HTTP error! Status: ${response.status}`); }
          return response.json();
        })
        .then(data => { this.pull_data(data.suggestions) })
        .catch(error => { console.error('Error fetching suggestions:', error); });
  }

  pull_data(suggestions) {
    this.suggestionsTarget.textContent = '';
    if (suggestions.length > 0) {
      this.append("Выберите один из вариантов...", true);
      suggestions.forEach((value) => { this.append(value["unrestricted_value"]); });
      this.suggestionsTarget.style = "display: block;"
    } else {
      this.suggestionsTarget.style = "display: none;"
    }
  }

  append(text, first=false) {
    let suggestionElement = document.createElement("div");
    suggestionElement.classList.add("suggestion-item");
    if (!first) { suggestionElement.setAttribute("data-action", "click->dadata#setAddress"); }
    suggestionElement.textContent = text;
    this.suggestionsTarget.appendChild(suggestionElement);
  }

  setAddress(event) {
    const text = event.target.textContent;
    const regex = /^(\d{6}),\s/;
    const match = text.match(regex);

    if (match) {
      const postalCode = match[1];
      const remainingText = text.replace(regex, "");
      this.addressTarget.value = remainingText;
      this.post_codeTarget.value = parseInt(postalCode, 10);
    } else {
      this.addressTarget.value = text;
      this.post_codeTarget.value = '';
    }

    this.suggestionsTarget.style = "display: none;"
  }
}
