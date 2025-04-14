import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["esuggestions", "email"];

  searchEmail(event) {
    const query = event.target.value.trim();
    this.form_connection(query);
  }

  form_connection(query) {
    if (!query) {
      this.esuggestionsTarget.textContent = '';
      this.esuggestionsTarget.style = "display: none;"
      return;
    }

    this.fetch_dadata(query)
  }

  fetch_dadata(query) {
    const url = `/proxy/clean_email?email=${query}`;

    fetch(url)
        .then(response => {
          if (!response.ok) { throw new Error(`HTTP error! Status: ${response.status}`); }
          return response.text();
        })
        .then(response => {
          console.log(response);
          if (response[0]['email']) {
            this.pull_data(response[0]['email']);
          }
        })
        .catch(error => { console.error('Error fetching suggestions:', error); });
  }

  pull_data(email) {
    const suggestions = this.esuggestionsTarget;
    suggestions.textContent = '';

    let suggestionElement = document.createElement("div");
    suggestionElement.classList.add("suggestion-item");
    suggestionElement.setAttribute("data-action", "click->dadata-email#setEmail");
    suggestionElement.textContent = email;
    suggestions.appendChild(suggestionElement);

    suggestions.style = "display: block;"
  }

  setEmail(event) {
    this.emailTarget.value = event.target.textContent;
    this.esuggestionsTarget.style = "display: none;"
  }

  hidden() {
    setTimeout( () => {
      this.esuggestionsTarget.style = "display: none;"
    }, 300)
  }
}
