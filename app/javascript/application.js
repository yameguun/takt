// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails"
// import "controllers"

document.addEventListener('DOMContentLoaded', function() {
  // data-method="delete"を持つリンクを処理
  document.addEventListener('click', function(e) {
    const link = e.target.closest('a[data-method="delete"]');
    if (!link) return;

    e.preventDefault();

    // 確認ダイアログ
    const confirmMessage = link.dataset.confirm;
    if (confirmMessage && !confirm(confirmMessage)) {
      return;
    }

    // 動的フォーム生成
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = link.href;

    // _methodフィールド追加
    const methodInput = document.createElement('input');
    methodInput.type = 'hidden';
    methodInput.name = '_method';
    methodInput.value = 'delete';
    form.appendChild(methodInput);

    // CSRFトークン追加
    const csrfToken = document.querySelector('meta[name="csrf-token"]');
    if (csrfToken) {
      const tokenInput = document.createElement('input');
      tokenInput.type = 'hidden';
      tokenInput.name = 'authenticity_token';
      tokenInput.value = csrfToken.content;
      form.appendChild(tokenInput);
    }

    document.body.appendChild(form);
    form.submit();
  });
});

