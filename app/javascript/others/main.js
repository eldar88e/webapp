window.closeModal = function() {
    document.getElementById('modal').style.display = 'none';
};

window.openModal = function() {
    document.getElementById('modal').style.display = 'block';
};

window.closeMiniApp = function() {
    Telegram.WebApp.close();
};