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

  const menu = document.getElementById('rmd_menu');
  const logout = document.getElementById('logout');
  const offlineStatus = document.getElementById('rmd-offline-status');
  const scannableInputs = document.querySelectorAll('[data-scanner]');
  const cameraScan = document.getElementById('cameraScan');
  let webSocket;

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
    } else {
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
   * Event listeners for the RMD page.
   */
  const setupListeners = () => {
    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);
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
  const unpackScanValue = (val) => {
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
    this.rules.filter(r => this.expectedScanTypes.indexOf(r.type) !== -1).forEach((rule) => {
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

  /**
   * startScanner - set up the websocket connection and its callbacks.
   */
  const startScanner = () => {
    const wsUrl = 'ws://127.0.0.1:2115';

    if (webSocket !== undefined && webSocket.readyState !== WebSocket.CLOSED) { return; }
    webSocket = new WebSocket(wsUrl);

    webSocket.onopen = function onopen() {
      publicAPIs.logit('Connected...');
    };

    webSocket.onclose = function onclose() {
      publicAPIs.logit('Connection Closed...');
    };

    webSocket.onerror = function onerror(event) {
      publicAPIs.logit('Connection ERROR', event);
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
              e.form.submit();
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
    expectedScanTypes: this.expectedScanTypes,
    rules: this.rules,
    rulesForThisPage: this.rules.filter(r => this.expectedScanTypes.indexOf(r.type) !== -1),
  });

  /**
   * Init
   * Find the possible scan types in the page.
   * Call setupListeners to set up listeners for the page.
   * Call startScanner to make the websocket connection.
   *
   * @param {object} rules - the rules for identifying scan values.
   * @param {boolean} bypassRules - should the rules be ignores (scan any barcode).
   */
  publicAPIs.init = (rules, bypassRules) => {
    this.rules = rules;
    publicAPIs.bypassRules = bypassRules;
    this.expectedScanTypes = Array.from(document.querySelectorAll('[data-scan-rule]')).map(a => a.dataset.scanRule);
    this.expectedScanTypes = this.expectedScanTypes.filter((it, i, ar) => ar.indexOf(it) === i);

    setupListeners();

    startScanner();
  };

  //
  // Return the Public APIs
  //
  return publicAPIs;
}());
