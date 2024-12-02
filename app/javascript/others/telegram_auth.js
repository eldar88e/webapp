document.addEventListener("DOMContentLoaded", () => {
    const user = document.getElementById('user');
    if (user) {
        // console.log("Authenticated.");
    } else if ( typeof Telegram !== "undefined" && Telegram.WebApp) {

        if (userAgent.includes('telegram') || userAgent.includes('tgc')) {
            alert('Открыто в Telegram WebView');
        } else {
            alert('Не в Telegram WebView');
        }

        const initData = Telegram.WebApp.initData || "";

        fetch("/auth/telegram", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
            },
            body: JSON.stringify({ initData }),
        })
            .then((response) => response.json())
            .then((data) => {
                if (data.success) {
                    console.log("Authenticated:", data.user);
                    // window.location.href = "/";
                } else {
                    alert("Authentication failed: " + data.error);
                }
            })
            .catch((error) => {
                console.log("Error during authentication:", error);
            });
    } else {
        //alert("This app must be opened via Telegram WebApp.");
        document.body.innerHTML = '';
        const warning = document.createElement('div');
        warning.style.cssText = `
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        height: 100vh;
        text-align: center;
        font-family: Arial, sans-serif;
        font-size: 20px;
        color: red;
      `;
        warning.innerHTML = `<p><strong>This app must be opened via Telegram WebApp.</strong></p>`;
        document.body.appendChild(warning);
    }
});
