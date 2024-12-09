document.addEventListener("DOMContentLoaded", () => {
    const user = document.getElementById('user');
    if (user) {
        // console.log("Authenticated.");
    } else if ( typeof Telegram !== "undefined" && Telegram.WebApp) {
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
                    console.log("Authentication failed: " + data.error);
                    window.location.href = "https://t.me/atominexbot";
                }
            })
            .catch((error) => {
                console.log("Error during authentication:", error);
                window.location.href = "https://t.me/atominexbot";
            });
    } else {
        window.location.href = "https://t.me/atominexbot";
    }
});
