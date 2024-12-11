import { Controller } from "@hotwired/stimulus"
import {data} from "autoprefixer";

export default class extends Controller {
  static targets = ["suggestions", "suggestions_street", "address", "street", "post_code", "home", "apartment", "build"];
  static values = { id: Number }

  search(event) {
    const query = event.target.value.trim();
    let suggestions = this.suggestionsTarget;

    this.form_connection(query, suggestions);
  }

  search_street(event) {
    let query = event.target.value.trim();
    let suggestions = this.suggestions_streetTarget;
    let address = this.addressTarget.value.trim();
    if (address.length > 1) { query = `${address} ${query}`; }

    this.form_connection(query, suggestions);
  }

  form_connection(query, suggestions) {
    if (!query) {
      suggestions.textContent = '';
      suggestions.style = "display: none;"
      return;
    }

    let url = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address";
    let token = dadata_token;

    let options = {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Token " + token
      },
      body: JSON.stringify({query: query})
    };

    this.fetch_dadata(url, options, suggestions)
  }

  pull_data(data, suggestions) {
    suggestions.textContent = '';
    if (data.length > 0) {
      this.append("Выберите один из вариантов...", suggestions);
      window.suggestions_cache = data;
      data.forEach((value, index) => { this.append(value["unrestricted_value"], suggestions, index); });
      suggestions.style = "display: block;"
    } else {
      suggestions.style = "display: none;"
    }
  }

  append(text, suggestions, id=false) {
    let suggestionElement = document.createElement("div");
    suggestionElement.classList.add("suggestion-item");
    if (id !== false) {
      suggestionElement.setAttribute("data-dadata-id-value", id);
      suggestionElement.setAttribute("data-action", "click->dadata#setAddress");
    }
    suggestionElement.textContent = text;
    suggestions.appendChild(suggestionElement);
  }

  setAddress(event) {
    const idValue = event.target.dataset.dadataIdValue;
    const address = suggestions_cache[idValue]['data'];

    if (address['region_with_type']) {
      this.addressTarget.value = address['region_with_type'];
      if (address['area_with_type']) { this.addressTarget.value += `, ${address['area_with_type']}` }
      if (address['city_with_type'] && address['region_with_type'] !== address['city_with_type']) { this.addressTarget.value += `, ${address['city_with_type']}` }
      if (address['settlement_with_type']) { this.addressTarget.value += `, ${address['settlement_with_type']}` }
    } else {
      this.addressTarget.value = "";
    }
    this.streetTarget.value = address['street_with_type'] ? address['street_with_type'] : "";
    this.post_codeTarget.value = address['postal_code'] ? address['postal_code'] : "";
    this.homeTarget.value = address['house'] ? address['house'] : "";
    this.apartmentTarget.value = address['flat'] ? address['flat'] : "";
    this.buildTarget.value = address['stead'] ? address['stead'] : "";

    this.suggestionsTarget.style = "display: none;"
    this.suggestions_streetTarget.style = "display: none;"
  }

  fetch_dadata(url, options, suggestions) {
    fetch(url, options)
        .then(response => {
          if (!response.ok) { throw new Error(`HTTP error! Status: ${response.status}`); }
          return response.json();
        })
        .then(data => { this.pull_data(data.suggestions, suggestions) })
        .catch(error => { console.error('Error fetching suggestions:', error); });
  }
}
