window.closeModal = function() {
    document.getElementById('mainModal').classList.remove('show');
    document.getElementById('mainModal').style.display = 'none';
    document.body.classList.remove('modal-open');
    document.body.style.overflow = '';
    document.querySelector('.modal-backdrop').remove();
};

window.openModal = function() {
    document.getElementById('modal').style.display = 'block';
};
window.miniappClose = function() {
    Telegram.WebApp.close();
};