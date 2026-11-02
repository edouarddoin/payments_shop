// Entry point for the build script in your package.json
// Lazy load to make sure we only load the AdyenCheckout when we need it
document.addEventListener("turbo:load", async() => {
    if(!document.querySelector("#dropin-container")) return;

    try{
        const {initCheckout} = await import("./checkout");
        await initCheckout();
    } catch (error) {
        console.error("Error loading checkout module: Check in application.js file", error);
    }
});
import "@hotwired/turbo-rails"
import "./controllers"