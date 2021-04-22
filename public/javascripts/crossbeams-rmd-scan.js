const crossbeamsRmdScan = (function crossbeamsRmdScan() {
  //
  // Variables
  //
  const publicAPIs = { bypassRules: false };

  // New RMD logging:
  // const txtShow = document.getElementById('txtShow');
  // Old RMD logging:
  const ifrm = window.frameElement; // reference to iframe element container
  const doc = ifrm.ownerDocument;
  const txtShow = doc.getElementById('messages'); // OUTER FRAME...

  const form = document.querySelectorAll('.mobile_web_pdt_form_css_class, .pc_pdt_form_css_class')[0];
  const wifiIcon = document.getElementById('wifiIcon');
  const offlineMsg = document.getElementById('offlineMsg');
  const stdMsg = 'You are currently offline. Please check network settings and re-connect.';
  const subMsg = 'Attempting to process transation - waiting for connection. Please re-connect.';
  const menu = document.getElementById('rmd_menu');
  const logout = document.getElementById('logout');
  const offlineStatus = document.getElementById('rmd-offline-status');
  const scannableInputs = document.querySelectorAll('[data-scanner]');
  const cameraScan = document.getElementById('cameraScan');
  const wsStateDisplay = doc.getElementById('ws-state');
  let webSocket;
  let wifiConnected = true;
  let subTime;
  let subCount = 0;

  //
  // Methods
  //

  /**
   * Update the UI when the network connection is lost/regained.
   */
  const updateOnlineStatus = () => {
    if (navigator.onLine) {
      offlineStatus.style.display = 'none';
      if (menu) {
        menu.disabled = false;
      }
      if (logout) {
        logout.classList.remove('disableClick');
      }
      document.querySelectorAll('[data-rmd-btn]').forEach((node) => {
        node.disabled = false;
      });
      publicAPIs.logit('Online: network connection restored');
      wifiConnected = true;
    } else {
      wifiConnected = false;
      offlineStatus.style.display = '';
      if (menu) {
        menu.disabled = true;
      }
      if (logout) {
        logout.classList.add('disableClick');
      }
      document.querySelectorAll('[data-rmd-btn]').forEach((node) => {
        node.disabled = true;
      });
      publicAPIs.logit('Offline: network connection lost');
    }
  };

  /**
   * Disable a button and change its caption.
   * @param {element} button the button to disable.
   * @param {string} disabledText the text to use to replace the caption.
   * @returns {void}
   */
  const disableButton = (button, disabledText) => {
    button.dataset.enableWith = button.value;
    button.value = disabledText;
    button.classList.remove('dim');
    button.classList.add('o-50');
  };

  /**
   * Prevent multiple clicks of submit buttons.
   * @returns {void}
   */
  const preventMultipleSubmits = (element) => {
    disableButton(element, element.dataset.disableWith);
    window.setTimeout(() => {
      element.disabled = true;
    }, 0); // Disable the button with a delay so the form still submits...
  };

  /**
   * Handle form submission, delaying if the connection is not available.
   * @returns {void}
   */

  const formSubmitter = () => {
    // Note this might not work if the OS does not trigger on/offline events in the browser...
    // In that case we will need to trigger fetch requests to check the connection.
    if (wifiConnected) {
      if (subTime) {
        clearTimeout(subTime);
      }
      wifiIcon.classList.remove('wifiWait');
      offlineMsg.innerHTML = stdMsg;
      form.submit();
    } else {
      subCount += 1;
      publicAPIs.logit(`Attempting submit ${subCount}...`);
      wifiIcon.classList.add('wifiWait');
      offlineMsg.innerHTML = subMsg;
      subTime = setTimeout(() => {
        formSubmitter();
      }, 500);
    }
  }

  /**
   * Event listeners for the RMD page.
   */
  const setupListeners = () => {
    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);

    if (form) {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        subCount = 0;
        formSubmitter();
        return false;
      });
    } else {
      alert('Expected a form with the class "pc_pdt_form_css_class" but found none. Please call support.');
    }

    if (menu) {
      menu.addEventListener('change', (event) => {
        if (event.target.value !== '') {
          window.location = event.target.value;
        }
      });
    }
    document.body.addEventListener('click', (event) => {
      // Disable a button on click
      if (event.target.dataset && event.target.dataset.disableWith) {
        preventMultipleSubmits(event.target);
      }
    });
    if (cameraScan) {
      cameraScan.addEventListener('click', () => {
        webSocket.send('Type=key248_all');
      });
    }
  };

  /**
   * Apply scan rules to the scanned value
   * to dig out the actual value and type.
   *
   * @param {string} val - the scanned value.
   * @returns {object} success: boolean, value: the value, scanType: the type, error: string.
   */
  const unpackScanValue = (rawVal) => {
    const val = rawVal.split(/\r\n|\r|\n/)[0]; // remove newlines
    const res = { success: false };
    // If we can scan any barcode, return whatever was scanned:
    if (publicAPIs.bypassRules) {
      res.success = true;
      res.value = val;
      res.scanType = 'any';
      res.scanField = 'any';
      return res;
    }
    const matches = [];
    let rxp;
    publicAPIs.rules.filter(r => publicAPIs.expectedScanTypes.indexOf(r.type) !== -1).forEach((rule) => {
      rxp = RegExp(rule.regex);
      if (rxp.test(val)) {
        matches.push(rule.type);
        res.value = RegExp.lastParen;
        res.scanType = rule.type;
        res.scanField = rule.field;
      }
    });
    if (matches.length !== 1) {
      res.error = matches.length === 0 ? `${val} does not match any scannable rules` : 'Too many rules match';
    } else {
      res.success = true;
    }
    return res;
  };

  // Change the colour of an icon to depict the websocket state.
  const websocketStateDisplayChange = (connected) => {
    if (wsStateDisplay === undefined) { return; }
    wsStateDisplay.classList.remove('pending');
    if (connected) {
      wsStateDisplay.classList.add('connected');
      wsStateDisplay.classList.remove('disconnected');
    } else {
      wsStateDisplay.classList.add('disconnected');
      wsStateDisplay.classList.remove('connected');
    }
  };

  /**
   * startScanner - set up the websocket connection and its callbacks.
   */
  const startScanner = () => {
    const wsUrl = 'ws://127.0.0.1:2115';
    let connectedState = false;

    if (webSocket !== undefined && webSocket.readyState !== WebSocket.CLOSED) { return; }
    webSocket = new WebSocket(wsUrl);

    webSocket.onopen = function onopen() {
      websocketStateDisplayChange(true);
      connectedState = true;
      publicAPIs.logit('Connected...');
    };

    webSocket.onclose = function onclose() {
      websocketStateDisplayChange(false);
      connectedState = false;
      publicAPIs.logit('Connection Closed...');
      // delay for a second and try again...
      setTimeout(startScanner, 1000);
    };

    webSocket.onerror = function onerror(event) {
      if (connectedState) { // Ignore websocket errors if we are not connected.
        publicAPIs.logit('Connection ERROR', event);
      }
    };

    webSocket.onmessage = function onmessage(event) {
      if (event.data.includes('[SCAN]')) {
        const scanPack = unpackScanValue(event.data.split(',')[0].replace('[SCAN]', ''));
        if (!scanPack.success) {
          publicAPIs.logit(scanPack.error);
          return;
        }

        publicAPIs.logit('scanned', scanPack.value);
        let cnt = 0;
        scannableInputs.forEach((e) => {
          if (e.value === '' && cnt === 0 && (publicAPIs.bypassRules || e.dataset.scanRule === scanPack.scanType)) {
            e.value = scanPack.value;
            const field = document.getElementById(`${e.id}_scan_field`);
            if (field) {
              field.value = scanPack.scanField;
            }
            cnt += 1;
            if (e.dataset.submitForm) {
              subCount = 0;
              formSubmitter();
            }
          }
        });
      }
      console.info('Raw msg:', event.data);
    };
  };

  //
  // PUBLIC Methods
  //

  /**
   * Log to screen and console.
   *
   * @param {Array} args.
   */
  publicAPIs.logit = (...args) => {
    console.info(...args);
    if (txtShow !== null) {
      // New RMD logging:
      // txtShow.insertAdjacentHTML('beforeend', `${Array.from(args).map(a => (typeof (a) === 'string' ? a : JSON.stringify(a))).join(' ')}<br>`);
      // Old RMD logging:
      txtShow.value = `${Array.from(args).map(a => (typeof (a) === 'string' ? a : JSON.stringify(a))).join(' ')}\n` + txtShow.value;
    }
  };

  /**
   * show settings in use for this page.
   */
  publicAPIs.showSettings = () => ({
    expectedScanTypes: publicAPIs.expectedScanTypes,
    rules: publicAPIs.rules,
    rulesForThisPage: publicAPIs.rules.filter(r => publicAPIs.expectedScanTypes.indexOf(r.type) !== -1),
  });

  /**
   * Init
   * Find the possible scan types in the page.
   * Call setupListeners to set up listeners for the page.
   * Call startScanner to make the websocket connection.
   *
   * @param {object} rules - the rules for identifying scan values.
   * @param {boolean} bypassRules - should the rules be ignored (scan any barcode).
   */
  publicAPIs.init = (rules, bypassRules) => {
    publicAPIs.rules = rules;
    publicAPIs.bypassRules = bypassRules;
    publicAPIs.expectedScanTypes = Array.from(document.querySelectorAll('[data-scan-rule]')).map(a => a.dataset.scanRule);
    publicAPIs.expectedScanTypes = publicAPIs.expectedScanTypes.filter((it, i, ar) => ar.indexOf(it) === i);

    setupListeners();

    startScanner();
  };

  //
  // Return the Public APIs
  //
  return publicAPIs;
}());
