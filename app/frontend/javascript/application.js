window.closeModal = function() {
    const modal = document.getElementById('modal');
    const modalBlock = modal.querySelector('.modal-block');
    modalBlock.classList.toggle("open");
    setTimeout(() => {
        modal.style.display = 'none';
        modalBlock.innerHTML = '';
    }, 300);
};

window.openModal = function() {
    const modal = document.getElementById('modal');
    modal.style.display = 'flex';

    const modalBlock = modal.querySelector('.modal-block');
    setTimeout(() => {
        modalBlock.classList.toggle("open");
    }, 50);

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
