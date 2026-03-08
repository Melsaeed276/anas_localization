window.addEventListener('load', () => {
  if (!window.mermaid) {
    return;
  }

  window.mermaid.initialize({
    startOnLoad: true,
    securityLevel: 'loose',
    theme: 'default',
  });
});
