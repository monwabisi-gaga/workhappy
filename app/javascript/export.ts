const updateExportFeedback = (message: string): void => {
  const feedback = document.querySelector<HTMLElement>("[data-export-feedback]");
  if (feedback) feedback.textContent = message;
};

updateExportFeedback("CSV contains ID, status, date, and score.");
