document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector<HTMLFormElement>("[data-export-form]");
  const button = document.querySelector<HTMLButtonElement | HTMLInputElement>("[data-export-button]");
  const feedback = document.querySelector<HTMLElement>("[data-export-feedback]");

  if (!form || !button || !feedback) return;

  form.addEventListener("submit", () => {
    button.disabled = true;
    feedback.textContent = "Preparing download…";

    window.setTimeout(() => {
      button.disabled = false;
      feedback.textContent = "Download started.";
    }, 700);
  });
});
