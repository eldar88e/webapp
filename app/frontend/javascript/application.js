window.closeModal = function() {
    const modal = document.getElementById('modal');
    modal.style.display = 'none';

    const modalBlock = modal.querySelector('.modal-block');
    if (modalBlock) {
        modalBlock.innerHTML = '';
    }
};

window.openModal = function() {
    const modal = document.getElementById('modal');
    modal.style.display = 'flex';

    const handleOutsideClick = function(event) {
        if (event.target === modal) {
            closeModal();
        }
    };

    modal.addEventListener('click', handleOutsideClick, { once: true });
};

window.clearModal = function() {
    document.getElementById('modal').textContent = '';
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
