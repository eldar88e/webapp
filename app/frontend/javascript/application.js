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
