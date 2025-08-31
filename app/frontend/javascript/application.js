let handleOutsideClick;

window.closeModal = function () {
  const modal = document.getElementById("modal");
  const modalBlock = modal.querySelector(".modal-block");

  modalBlock.classList.toggle("open");

  if (handleOutsideClick) {
    modal.removeEventListener("click", handleOutsideClick);
    handleOutsideClick = null;
  }

  setTimeout(() => {
    modal.style.display = "none";
    document.getElementById("modal-block").innerHTML = "";
  }, 300);
};

window.openModal = function () {
  const modal = document.getElementById("modal");
  const modalBlock = modal.querySelector(".modal-block");

  modal.style.display = "flex";

  setTimeout(() => {
    modalBlock.classList.toggle("open");
  }, 50);

  handleOutsideClick = function (event) {
    if (event.target === modal) {
      closeModal();
    }
  };

  modal.addEventListener("click", handleOutsideClick);
};

window.clearModal = function () {
  document.getElementById("modal").textContent = "";
};

window.leftModal = function () {
  document.getElementById("modal").classList.add("left");
  document.getElementById("modal").classList.remove("right");
};

window.rightModal = function () {
  document.getElementById("modal").classList.add("right");
  document.getElementById("modal").classList.remove("left");
};

window.closeMiniApp = function () {
  Telegram.WebApp.close();
};

if ("serviceWorker" in navigator) {
  window.addEventListener("load", function () {
    navigator.serviceWorker
      .register("/service-worker.js")
      .then(function () {
        // ...
      })
      .catch(function (error) {
        console.log("Error registering ServiceWorker:", error);
      });
  });
}
