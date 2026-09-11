/* eslint-disable max-classes-per-file -- loaded only on pages with uploads */
import { Controller } from "@hotwired/stimulus";
import Dropzone from "dropzone";
import { DirectUpload } from "@rails/activestorage";
import { getMetaValue, findElement, removeElement, insertAfter } from "../helpers/index";

function createDirectUpload(file, url, controller) {
  return new DirectUpload(file, url, controller);
}

class DirectUploadController {
  constructor(source, file) {
    this.directUpload = createDirectUpload(file, source.url, this);
    this.source = source;
    this.file = file;
  }

  start() {
    this.file.controller = this;
    this.hiddenInput = this.createHiddenInput();
    this.directUpload.create((error, attributes) => {
      if (error) {
        removeElement(this.hiddenInput);
        this.emitDropzoneError(error);
      } else {
        this.hiddenInput.value = attributes.signed_id;
        this.emitDropzoneSuccess();
      }
    });
  }

  createHiddenInput() {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = this.source.inputTarget.name;
    insertAfter(input, this.source.inputTarget);
    return input;
  }

  directUploadWillStoreFileWithXHR(xhr) {
    // xhr.setRequestHeader("x-amz-acl", "public-read");
    this.bindProgressEvent(xhr);
    this.emitDropzoneUploading();
  }

  bindProgressEvent(xhr) {
    this.xhr = xhr;
    this.xhr.upload.addEventListener("progress", (event) =>
      this.uploadRequestDidProgress(event)
    );
  }

  uploadRequestDidProgress(event) {
    const { element } = this.source;
    const progress = (event.loaded / event.total) * 100;
    findElement(
      this.file.previewTemplate,
      ".dz-upload"
    ).style.width = `${progress}%`;
  }

  emitDropzoneUploading() {
    this.file.status = Dropzone.UPLOADING;
    this.source.dropZone.emit("processing", this.file);
  }

  emitDropzoneError(error) {
    this.file.status = Dropzone.ERROR;
    this.source.dropZone.emit("error", this.file, error);
    this.source.dropZone.emit("complete", this.file);
  }

  emitDropzoneSuccess() {
    this.file.status = Dropzone.SUCCESS;
    this.source.dropZone.emit("success", this.file);
    this.source.dropZone.emit("complete", this.file);
    this.source.doneCheckTarget.checked = true;
    this.source.fileNameTarget.innerHTML = this.file.name;
    // if ($("#frontFileName").text() === $("#backFileName").text()) {
    //   $("#fileMatchError").show();
    // } else {
    //   $("#fileMatchError").hide();
    // }
  }
}

function createDirectUploadController(source, file) {
  return new DirectUploadController(source, file);
}

function createDropZone(controller) {
  const dropzoneElement = controller.element.querySelector(".profile-dropzone");
  return new Dropzone(dropzoneElement, {
    url: controller.url,
    headers: controller.headers,
    maxFiles: controller.maxFiles,
    maxFilesize: controller.maxFileSize,
    acceptedFiles: controller.acceptedFiles,
    // addRemoveLinks: controller.addRemoveLinks,
    autoQueue: false,
    clickable: false,
    dictDefaultMessage: "Drop files here to upload",
    // dictFallbackMessage:
    //   "Your browser does not support drag'n'drop file uploads.",
    // dictFallbackText:
    //   "Please use the fallback form below to upload your files like in the olden days.",
    // dictFileTooBig:
    //   "File is too big ({{filesize}}MiB). Max filesize: {{maxFilesize}}MiB.",
    dictInvalidFileType: "File type not supported",
    // dictResponseError: "Server responded with {{statusCode}} code.",
    // dictCancelUpload: "Cancel upload",
    // dictCancelUploadConfirmation:
    //   "Are you sure you want to cancel this upload?",
    dictRemoveFile: "Delete",
    dictMaxFilesExceeded: "only one file allowed",
    // init: function () {
    //   this.on("addedfile", function (file) {
    //     // Hide remove link for the first file
    //     if (this.files.length === 1) {
    //       const removeLink = file.previewElement.querySelector(".dz-remove");
    //       if (removeLink) {
    //         removeLink.style.display = "none";
    //       }
    //     }
    //   });
    // },
  });
}

export default class extends Controller {
  static targets = ["input", "doneCheck", "fileName", "queueCheck"];

  connect() {
    this.dropZone = createDropZone(this);
    this.hideFileInput();
    this.bindEvents();
    this._createHiddenFileInput();
    Dropzone.autoDiscover = false; // necessary quirk for Dropzone error in console
  }

  // Private
  hideFileInput() {
    this.inputTarget.disabled = true;
    this.inputTarget.style.display = "none";
  }
   _createHiddenFileInput() {
  this._hiddenFileInput = document.createElement("input");
  this._hiddenFileInput.type = "file";
  this._hiddenFileInput.accept = this.acceptedFiles;
  this._hiddenFileInput.style.display = "none";
  document.body.appendChild(this._hiddenFileInput);

  this._hiddenFileInput.addEventListener("change", (e) => {
    const file = e.target.files[0];
    if (file) {
      this.dropZone.addFile(file);
    }
    this._hiddenFileInput.value = "";
  });
  }
  openFilePicker() {
    this._hiddenFileInput.click();
  }
  // bindEvents() {
  //   this.dropZone.on("addedfile", (file) => {
  //     if (this.hasQueueCheckTarget) {
  //       this.queueCheckTarget.checked = false;
  //     }
  //     setTimeout(() => {
  //       file.accepted && createDirectUploadController(this, file).start();
  //     }, 500);
  //   });

  //   this.dropZone.on("removedfile", (file) => {
  //     file.controller && removeElement(file.controller.hiddenInput);
  //     this.doneCheckTarget.checked = this.dropZone.getAcceptedFiles().length > 0;
  //     // $("#fileMatchError").hide();
  //   });

  //   this.dropZone.on("canceled", (file) => {
  //     file.controller && file.controller.xhr.abort();
  //   });

  //   this.dropZone.on("queuecomplete", () => {
  //     if (this.hasQueueCheckTarget) {
  //     this.queueCheckTarget.checked = true;
  //     }
  //   });
  // }
  bindEvents() {
    this.dropZone.on("addedfile", (file) => {
      if (this.dropZone.files.length > 1) {
        // Remove the previously added file
        const previousFile = this.dropZone.files[0];
        this.dropZone.removeFile(previousFile);
      }
  
      if (this.hasQueueCheckTarget) {
        this.queueCheckTarget.checked = false;
      }
  
      setTimeout(() => {
        file.accepted && createDirectUploadController(this, file).start();
      }, 500);
    });
  
    this.dropZone.on("removedfile", (file) => {
      file.controller && removeElement(file.controller.hiddenInput);
      this.doneCheckTarget.checked = this.dropZone.getAcceptedFiles().length > 0;
    });
  
    this.dropZone.on("canceled", (file) => {
      file.controller && file.controller.xhr.abort();
    });
  
    this.dropZone.on("queuecomplete", () => {
      if (this.hasQueueCheckTarget) {
        this.queueCheckTarget.checked = true;
      }
    });
  }
  

  get headers() {
    return { "X-CSRF-Token": getMetaValue("csrf-token") };
  }

  get url() {
    return this.inputTarget.getAttribute("data-direct-upload-url");
  }

  get maxFiles() {
    return this.data.get("maxFiles");
  }

  get maxFileSize() {
    return this.data.get("maxFileSize") || 256;
  }

  get acceptedFiles() {
    return this.data.get("acceptedFiles");
  }

  get addRemoveLinks() {
    return this.data.get("addRemoveLinks") || true;
  }
}
