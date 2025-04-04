import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        this.observer = new IntersectionObserver(entries => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    setTimeout(() => {
                        this.loadMore();
                    }, 300);
                }
            });
        });
        this.observer.observe(this.element);
    }

    loadMore() {
        const url = this.data.get("url");
        if (url) {
            fetch(url, { headers: { Accept: "text/vnd.turbo-stream.html" } })
                .then(response => response.text())
                .then(html => {
                    // Вставляем полученный turbo stream до блока пагинации
                    this.element.insertAdjacentHTML("beforebegin", html);
                })
                .catch(error => console.error("Ошибка загрузки следующей порции:", error));
        }
    }

    disconnect() {
        this.observer.disconnect();
    }
}
