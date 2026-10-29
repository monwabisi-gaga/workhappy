(() => {
  // app/javascript/export.ts
  document.addEventListener("DOMContentLoaded", () => {
    const form = document.querySelector("[data-export-form]");
    const button = document.querySelector("[data-export-button]");
    const feedback = document.querySelector("[data-export-feedback]");
    if (!form || !button || !feedback) return;
    form.addEventListener("submit", () => {
      button.disabled = true;
      feedback.textContent = "Preparing download\u2026";
      window.setTimeout(() => {
        button.disabled = false;
        feedback.textContent = "Download started.";
      }, 700);
    });
  });
})();
