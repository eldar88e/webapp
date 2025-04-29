import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suggestions", "name"];

  connect() {
    this.fio = {};
    window.gender = null;
  }

  search(event) {
    const query = event.target.value.trim();
    this.formConnection(query, 'surname');
  }

  searchName(event) {
    const query = event.target.value.trim();
    this.formConnection(query, 'name');
  }

  searchLast(event) {
    const query = event.target.value.trim();
    this.formConnection(query, 'patronymic');
  }

  formConnection(query, type) {
    if (!query) {
      this.suggestionsTarget.style.display = "none";
      this.suggestionsTarget.parentElement.style.display = "none";
      this.suggestionsTarget.textContent = '';
      return;
    }
    if (this.fio[type] === query) {
      this.suggestionsTarget.style.display = "block";
      this.suggestionsTarget.parentElement.style.display = "block";
      return;
    }

    this.fio[type] = query;
    this.fetchDadata(query, type)
  }

  fetchDadata(query, type) {
    const url = "//suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/fio";
    const options = {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Token " + dadata_token
      },
      body: JSON.stringify({ query: query })
    };

    fetch(url, options)
        .then(response => {
          if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);

          return response.json();
        })
        .then(data => { this.pullData(data.suggestions, type); })
        .catch(error => { console.error('Error fetching suggestions:', error); });
  }

  pullData(data, type) {
    const suggestions = this.suggestionsTarget;
    suggestions.textContent = '';

    if (data.length > 0) {
      const filteredData = this.filterData(data, type);
      if (filteredData.length < 1) {
        suggestions.style.display = "none";
        suggestions.parentElement.style.display = "none";
        return;
      }

      let suggestionElement = this.createSuggestionItem();
      suggestions.appendChild(suggestionElement);
      filteredData.forEach((value) => {
        this.appendSuggestion(value, suggestions, type);
      });
      suggestions.style.display = "block";
      suggestions.parentElement.style.display = "block";
    } else {
      suggestions.style.display = "none";
      suggestions.parentElement.style.display = "none";
    }
  }

  filterData(data, type) {
    if (type === 'surname') window.gender = null;

    return data.filter(item => {
      if (!item["data"][type]) return false;
      if (window.gender && item["data"]["gender"] !== "UNKNOWN" && item["data"]["gender"] !== window.gender) return false;

      return true;
    });
  }

  appendSuggestion(item, suggestions, type) {
    let suggestionElement = this.createSuggestionItem(item["data"][type]);
    suggestionElement.setAttribute("data-gender", item["data"]["gender"]);
    suggestionElement.setAttribute("data-action", "click->dadata-name#setName");
    suggestions.appendChild(suggestionElement);
  }

  createSuggestionItem(content='') {
    let suggestionElement = document.createElement("div");
    suggestionElement.classList.add("suggestion-item");
    suggestionElement.textContent = content
    return suggestionElement
  }

  setName(event) {
    this.nameTarget.value = event.target.textContent;
    window.gender ??= event.target.dataset.gender;
    const nameValue = this.nameTarget.getAttribute("name");
    nameValue === "user[middle_name]" ? this.fio.surname = this.nameTarget.value : this.fio.name = this.nameTarget.value;
    this.suggestionsTarget.style.display = "none";
    this.suggestionsTarget.parentElement.style.display = "none";
  }

  hidden() {
    setTimeout( () => {
      this.suggestionsTarget.style.display = "none";
      this.suggestionsTarget.parentElement.style.display = "none";
    }, 300)
  }
}
