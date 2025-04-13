import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["esuggestions"];

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
      suggestionElement.setAttribute("data-action", "click->dadata#setEmail");
    }
    suggestionElement.textContent = text;
    suggestions.appendChild(suggestionElement);
  }

  setEmail(event) {
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

  fetch_dadata(query) {
    const url = "https://cleaner.dadata.ru/api/v1/clean/email";
    const suggestions = this.esuggestionsTarget;
    const options = {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": `Token ${dadata_token}`,
        "X-Secret": dadata_secret_key
      },
      body: JSON.stringify([query])
    };

    console.log(options);

    fetch(url, options)
         .then(response => {
           if (!response.ok) { throw new Error(`HTTP error! Status: ${response.status}`); }
           return response.text();
         })
        //.then(data => { this.pull_data(data.suggestions, suggestions) })
        .then(result => { console.log(result) })
        .catch(error => { console.error('Error fetching suggestions:', error); });
  }
}
