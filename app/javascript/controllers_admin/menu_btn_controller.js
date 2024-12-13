import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    connect() {
        console.log(document.getElementById('sidebarBackdrop').style.display);
    }

    showMenu() {
        let sidebarBackdrop = document.getElementById('sidebarBackdrop');
        let sidebar = document.getElementById('sidebar');

        console.log(sidebar.style.display);

        if (sidebar.style.display === 'none' && sidebar.style.display === 'none') {
            sidebar.style = "display: block;";
            sidebarBackdrop.style = "display: block;";
        } else {
            sidebar.style = "display: none;";
            sidebarBackdrop.style = "display: none;";
        }
    }
}