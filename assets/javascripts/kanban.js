var KanbanBoard = (function () {
  var config = {};
  var draggedCard = null;
  var pendingMove = null;
  var isMoving = false;
  var SELECTORS = {
    cardDraggable: '.kanban-card[draggable="true"]',
    card: '.kanban-card',
    column: '.kanban-column',
    columnContent: '.kanban-column-content',
    count: '.kanban-count',
    emptyState: '.kanban-empty-state',
    notification: '#kanban-notification'
  };
  var CLASSES = {
    dragging: 'dragging',
    dragOver: 'drag-over',
    emptyState: 'kanban-empty-state',
    closedCard: 'kanban-card--closed'
  };

  function init(options) {
    config = options || {};
    if (config.canMove) {
      setupDragDrop();
    }
  }

  function setupDragDrop() {
    document.querySelectorAll(SELECTORS.cardDraggable).forEach(bindCard);

    document.querySelectorAll(SELECTORS.columnContent).forEach(function (col) {
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
    this.classList.add(CLASSES.dragging);
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', this.dataset.issueId);
  }

  function onDragEnd() {
    this.classList.remove(CLASSES.dragging);
    document.querySelectorAll(SELECTORS.column).forEach(function (c) {
      c.classList.remove(CLASSES.dragOver);
    });

    if (pendingMove && !isMoving) {
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
    this.closest(SELECTORS.column).classList.add(CLASSES.dragOver);
  }

  function onDragLeave(e) {
    var col = this.closest(SELECTORS.column);
    if (!col.contains(e.relatedTarget)) col.classList.remove(CLASSES.dragOver);
  }

  function onDrop(e) {
    e.preventDefault();

    if (isMoving) return;

    var targetColEl   = this.closest(SELECTORS.column);
    var targetContent = this;
    targetColEl.classList.remove(CLASSES.dragOver);

    var issueId     = e.dataTransfer.getData('text/plain');
    var newStatusId = targetColEl.dataset.statusId;

    if (!issueId || !newStatusId || !draggedCard) return;

    var sourceColEl = draggedCard.closest(SELECTORS.column);
    if (sourceColEl && sourceColEl.dataset.statusId === newStatusId) return;

    pendingMove = {
      card:          draggedCard,
      targetContent: targetContent,
      issueId:       issueId,
      newStatusId:   newStatusId
    };
  }

  function applyMove(card, targetContent, issueId, newStatusId) {
    if (isMoving) return;
    isMoving = true;

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
      isMoving = false;

      if (xhr.status >= 200 && xhr.status < 300 && data.success) {
        // If the card lands in a closed column, we add a visual of the closed column.
        var targetCol = targetContent.closest(SELECTORS.column);
        setCardClosedState(card, targetCol);
        showNotification(config.i18n?.moveSuccess, 'success');
      } else {
        rollbackMove(card, originalParent, originalNextSibling);
        showNotification(data.message || config.i18n?.updateError, 'error');
      }
    };

    xhr.onerror = function () {
      isMoving = false;
      rollbackMove(card, originalParent, originalNextSibling);
      showNotification(config.i18n?.networkError, 'error');
    };

    xhr.send(JSON.stringify({ issue_id: issueId, new_status_id: newStatusId }));
  }

  function rollbackMove(card, originalParent, originalNextSibling) {
    if (originalNextSibling) {
      originalParent.insertBefore(card, originalNextSibling);
    } else {
      originalParent.appendChild(card);
    }
    updateCounts();
  }

  function setCardClosedState(card, column) {
    if (column && column.dataset.closed === 'true') {
      card.classList.add(CLASSES.closedCard);
    } else {
      card.classList.remove(CLASSES.closedCard);
    }
  }

  function updateCounts() {
    document.querySelectorAll(SELECTORS.column).forEach(function (col) {
      var count = col.querySelectorAll(SELECTORS.card).length;
      var badge = col.querySelector(SELECTORS.count);
      var body  = col.querySelector(SELECTORS.columnContent);
      var empty = col.querySelector(SELECTORS.emptyState);

      if (badge) badge.textContent = count;

      if (count === 0 && !empty) {
        var div = document.createElement('div');
        div.className = CLASSES.emptyState;
        div.textContent = config.i18n?.noIssues;
        body.appendChild(div);
      } else if (count > 0 && empty) {
        empty.remove();
      }
    });
  }

  function showNotification(msg, type) {
    var el = document.querySelector(SELECTORS.notification);
    if (!el) return;
    el.textContent   = msg;
    el.className     = 'notification ' + type;
    el.style.display = 'block';
    clearTimeout(el._hideTimer);
    el._hideTimer = setTimeout(function () { el.style.display = 'none'; }, 3000);
  }

  return { init: init };
})();
