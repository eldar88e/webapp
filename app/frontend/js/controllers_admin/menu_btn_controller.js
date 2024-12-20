import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["body"];

    showMenu() {
        let sidebarBackdrop = document.getElementById('sidebarBackdrop');
        let sidebar = document.getElementById('sidebar');

        if (sidebar.style.display === 'flex') {
        //    sidebar.style = "display: none;";
        //    sidebarBackdrop.style = "display: none;";
        } else {
        //    sidebar.style = "display: flex;";
        //    sidebarBackdrop.style = "display: flex;";
        }

        if (this.element.classList.contains('aside-hide')) {
            this.element.classList.remove('aside-hide');
        } else {
            this.element.classList.add('aside-hide');
        }
    }
}
