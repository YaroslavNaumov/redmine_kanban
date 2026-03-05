var KanbanBoard = (function () {
  var config = {};
  var draggedCard = null;
  var pendingMove = null;

  function init(options) {
    config = options || {};
    if (config.canMove) {
      setupDragDrop();
    }
  }

  function setupDragDrop() {
    document.querySelectorAll('.kanban-card[draggable="true"]').forEach(bindCard);

    document.querySelectorAll('.kanban-column-content').forEach(function (col) {
      col.addEventListener('dragover',  onDragOver);
      col.addEventListener('dragleave', onDragLeave);
      col.addEventListener('drop',      onDrop);
    });
  }

  function bindCard(card) {
    card.addEventListener('dragstart', onDragStart);
    card.addEventListener('dragend',   onDragEnd);
  }

  function onDragStart(e) {
    draggedCard = this;
    this.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', this.dataset.issueId);
  }

  function onDragEnd() {
    this.classList.remove('dragging');
    document.querySelectorAll('.kanban-column').forEach(function (c) {
      c.classList.remove('drag-over');
    });

    if (pendingMove) {
      var move = pendingMove;
      pendingMove = null;
      setTimeout(function () {
        applyMove(move.card, move.targetContent, move.issueId, move.newStatusId);
      }, 0);
    }

    draggedCard = null;
  }

  function onDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    this.closest('.kanban-column').classList.add('drag-over');
  }

  function onDragLeave(e) {
    var col = this.closest('.kanban-column');
    if (!col.contains(e.relatedTarget)) col.classList.remove('drag-over');
  }

  function onDrop(e) {
    e.preventDefault();

    var targetColEl   = this.closest('.kanban-column');
    var targetContent = this;
    targetColEl.classList.remove('drag-over');

    var issueId     = e.dataTransfer.getData('text/plain');
    var newStatusId = targetColEl.dataset.statusId;

    if (!issueId || !newStatusId || !draggedCard) return;

    var sourceColEl = draggedCard.closest('.kanban-column');
    if (sourceColEl && sourceColEl.dataset.statusId === newStatusId) return;

    pendingMove = {
      card:          draggedCard,
      targetContent: targetContent,
      issueId:       issueId,
      newStatusId:   newStatusId
    };
  }

  function applyMove(card, targetContent, issueId, newStatusId) {
    var originalParent      = card.parentNode;
    var originalNextSibling = card.nextSibling;

    targetContent.insertBefore(card, targetContent.firstChild);
    updateCounts();

    var xhr = new XMLHttpRequest();
    xhr.open('POST', config.moveIssueUrl, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('X-CSRF-Token', config.csrfToken);
    xhr.setRequestHeader('Accept', 'application/json');

    xhr.onload = function () {
      var data;
      try { data = JSON.parse(xhr.responseText); } catch (err) { data = {}; }

      if (xhr.status >= 200 && xhr.status < 300 && data.success) {
        // If the card lands in a closed column, we add a visual of the closed column.
        var targetCol = targetContent.closest('.kanban-column');
        if (targetCol && targetCol.dataset.closed === 'true') {
          card.classList.add('kanban-card--closed');
        } else {
          card.classList.remove('kanban-card--closed');
        }
        showNotification(data.message || 'The task has been moved', 'success');
      } else {
        if (originalNextSibling) {
          originalParent.insertBefore(card, originalNextSibling);
        } else {
          originalParent.appendChild(card);
        }
        updateCounts();
        showNotification(data.message || 'Error updating task', 'error');
      }
    };

    xhr.onerror = function () {
      if (originalNextSibling) {
        originalParent.insertBefore(card, originalNextSibling);
      } else {
        originalParent.appendChild(card);
      }
      updateCounts();
      showNotification('Network error', 'error');
    };

    xhr.send(JSON.stringify({ issue_id: issueId, new_status_id: newStatusId }));
  }

  function updateCounts() {
    document.querySelectorAll('.kanban-column').forEach(function (col) {
      var count = col.querySelectorAll('.kanban-card').length;
      var badge = col.querySelector('.kanban-count');
      var body  = col.querySelector('.kanban-column-content');
      var empty = col.querySelector('.kanban-empty-state');

      if (badge) badge.textContent = count;

      if (count === 0 && !empty) {
        var div = document.createElement('div');
        div.className = 'kanban-empty-state';
        div.textContent = 'No tasks';
        body.appendChild(div);
      } else if (count > 0 && empty) {
        empty.remove();
      }
    });
  }

  function showNotification(msg, type) {
    var el = document.getElementById('kanban-notification');
    if (!el) return;
    el.textContent   = msg;
    el.className     = 'notification ' + type;
    el.style.display = 'block';
    clearTimeout(el._hideTimer);
    el._hideTimer = setTimeout(function () { el.style.display = 'none'; }, 3000);
  }

  return { init: init };
})();
