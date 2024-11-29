document.addEventListener("DOMContentLoaded", () => {
    const user = document.getElementById('user');
    if ( !user && typeof Telegram !== "undefined" && Telegram.WebApp) {
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
                    window.location.href = "/";
                } else {
                    alert("Authentication failed: " + data.error);
                }
            })
            .catch((error) => {
                console.error("Error during authentication:", error);
            });
    } else {
        alert("This app must be opened via Telegram WebApp.");
    }
});
