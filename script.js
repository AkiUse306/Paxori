const progressBar = document.getElementById('progressBar');
const dropZone = document.getElementById('dropZone');
const fileInput = document.getElementById('fileInput');
const fileList = document.getElementById('fileList');
const transferButton = document.getElementById('transferButton');
const timeline = document.getElementById('timeline');
const transferResults = document.getElementById('transferResults');
const uploadedFiles = document.getElementById('uploadedFiles');
const deviceSelect = document.getElementById('deviceSelect');

const addTimelineEntry = (message) => {
  if (!timeline) return;
  const item = document.createElement('li');
  item.textContent = message;
  timeline.prepend(item);
};

const updateFileList = (files) => {
  if (!fileList) return;
  if (!files.length) {
    fileList.innerHTML = '<p class="empty-state">No files selected yet.</p>';
    return;
  }

  fileList.innerHTML = '';
  files.forEach((file) => {
    const item = document.createElement('div');
    item.className = 'file-item';
    const label = document.createElement('span');
    label.textContent = file.name;
    const meta = document.createElement('small');
    meta.textContent = `${Math.max(1, Math.round(file.size / 1024))} KB`;
    item.appendChild(label);
    item.appendChild(meta);
    fileList.appendChild(item);
  });
};

const renderTransferResults = (response) => {
  if (!transferResults) return;
  transferResults.innerHTML = '';
  const heading = document.createElement('h4');
  heading.textContent = 'Transfer details';
  transferResults.appendChild(heading);

  response.files.forEach((file) => {
    const item = document.createElement('div');
    item.className = 'transfer-result-item';
    item.innerHTML = `
      <strong>${file.originalName}</strong>
      <span>${Math.round(file.size / 1024)} KB</span>
      <a href="${file.path}" target="_blank">Download copy</a>
    `;
    transferResults.appendChild(item);
  });
};

const renderUploadedFiles = (files) => {
  if (!uploadedFiles) return;
  if (!files.length) {
    uploadedFiles.innerHTML = '<p class="empty-state">No files uploaded yet.</p>';
    return;
  }

  uploadedFiles.innerHTML = '';
  files.forEach((file) => {
    const item = document.createElement('div');
    item.className = 'uploaded-file';
    item.innerHTML = `<a href="${file.url}" target="_blank">${file.name}</a>`;
    uploadedFiles.appendChild(item);
  });
};

const selectedFiles = [];

const fetchUploadedFiles = async () => {
  try {
    const response = await fetch('/api/uploads');
    if (!response.ok) return;
    const data = await response.json();
    renderUploadedFiles(data);
  } catch (error) {
    console.error('Unable to fetch uploaded files', error);
  }
};

updateFileList(selectedFiles);
fetchUploadedFiles();

if (progressBar) {
  let value = 0;
  const tick = () => {
    value += 1.8;
    if (value > 100) value = 0;
    progressBar.style.width = `${Math.min(value, 100)}%`;
    window.requestAnimationFrame(tick);
  };
  window.requestAnimationFrame(tick);
}

if (dropZone && fileInput) {
  ['dragenter', 'dragover'].forEach((eventName) => {
    dropZone.addEventListener(eventName, (event) => {
      event.preventDefault();
      dropZone.classList.add('drag-over');
    });
  });

  ['dragleave', 'dragend', 'drop'].forEach((eventName) => {
    dropZone.addEventListener(eventName, () => {
      dropZone.classList.remove('drag-over');
    });
  });

  dropZone.addEventListener('drop', (event) => {
    event.preventDefault();
    const droppedFiles = Array.from(event.dataTransfer?.files || []);
    droppedFiles.forEach((file) => selectedFiles.push(file));
    updateFileList(selectedFiles);
    addTimelineEntry(`Dropped ${droppedFiles.length} file${droppedFiles.length > 1 ? 's' : ''} into the studio.`);
  });

  fileInput.addEventListener('change', (event) => {
    const chosenFiles = Array.from(event.target.files || []);
    chosenFiles.forEach((file) => selectedFiles.push(file));
    updateFileList(selectedFiles);
    addTimelineEntry(`Selected ${chosenFiles.length} file${chosenFiles.length > 1 ? 's' : ''} from the device.`);
  });
}

if (transferButton) {
  transferButton.addEventListener('click', async () => {
    if (!selectedFiles.length) {
      addTimelineEntry('No files selected. Add items to begin a transfer.');
      return;
    }

    const destination = deviceSelect?.value || 'Unknown device';
    transferButton.disabled = true;
    transferButton.textContent = 'Transferring...';
    addTimelineEntry(`Beginning transfer to ${destination}.`);

    const formData = new FormData();
    selectedFiles.forEach((file) => formData.append('files', file));
    formData.append('destination', destination);

    try {
      const response = await fetch('/api/transfer', {
        method: 'POST',
        body: formData
      });

      if (!response.ok) {
        throw new Error('Transfer failed.');
      }

      const data = await response.json();
      renderTransferResults(data);
      addTimelineEntry(`Transfer completed to ${destination}. ${data.files.length} file${data.files.length > 1 ? 's' : ''} delivered.`);
      selectedFiles.length = 0;
      updateFileList(selectedFiles);
      await fetchUploadedFiles();
      transferButton.textContent = 'Start secure transfer';
    } catch (error) {
      addTimelineEntry('Transfer failed. Please try again.');
      transferButton.textContent = 'Retry transfer';
    } finally {
      transferButton.disabled = false;
    }
  });
}
