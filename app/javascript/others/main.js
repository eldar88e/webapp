window.closeModal = function() {
    document.getElementById('modal').style.display = 'none';
};

window.openModal = function() {
    document.getElementById('modal').style.display = 'block';
};

window.leftModal = function() {
    document.getElementById('modal').classList.add('left');
    document.getElementById('modal').classList.remove('right');
};

window.rightModal = function() {
    document.getElementById('modal').classList.add('right');
    document.getElementById('modal').classList.remove('left');
}

window.closeMiniApp = function() {
    Telegram.WebApp.close();
};