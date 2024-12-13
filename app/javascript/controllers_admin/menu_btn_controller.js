import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    showMenu() {
        let sidebarBackdrop = document.getElementById('sidebarBackdrop');
        let sidebar = document.getElementById('sidebar');

        if (sidebar.style.display === 'none' && sidebar.style.display === 'none') {
            sidebar.style = "display: block;";
            sidebarBackdrop.style = "display: block;";
        } else {
            sidebar.style = "display: none;";
            sidebarBackdrop.style = "display: none;";
        }
    }
}
