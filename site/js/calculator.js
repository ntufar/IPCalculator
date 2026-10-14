/*
 * Calculator page controller.
 * Reads the octet fields and the prefix, then renders IPv4.results().
 */
(function () {
    'use strict';

    var octetInputs = [0, 1, 2, 3].map(function (i) {
        return document.getElementById('oct-' + i);
    });
    var prefixInput = document.getElementById('prefix');
    var prefixRange = document.getElementById('prefix-range');
    var errorEl = document.getElementById('error');
    var networkEl = document.getElementById('network');
    var networkValue = networkEl.querySelector('.network-value');
    var resultsEl = document.getElementById('results');
    var toastEl = document.getElementById('toast');
    var toastTimer = null;

    function isOctet(text) {
        return /^\d{1,3}$/.test(text) && Number(text) <= 255;
    }

    function isPrefix(text) {
        return /^\d{1,2}$/.test(text) && Number(text) <= 32;
    }

    function showError(message) {
        errorEl.textContent = message;
        errorEl.hidden = false;
    }

    function clearError() {
        errorEl.textContent = '';
        errorEl.hidden = true;
    }

    function setInvalid(input, invalid) {
        if (invalid) {
            input.setAttribute('aria-invalid', 'true');
        } else {
            input.removeAttribute('aria-invalid');
        }
    }

    /** Copy text with the async API. Fall back to a hidden textarea. */
    function copyText(text) {
        if (navigator.clipboard && window.isSecureContext) {
            return navigator.clipboard.writeText(text);
        }
        return new Promise(function (resolve, reject) {
            var area = document.createElement('textarea');
            area.value = text;
            area.setAttribute('readonly', '');
            area.style.position = 'fixed';
            area.style.opacity = '0';
            document.body.appendChild(area);
            area.select();
            try {
                if (document.execCommand('copy')) {
                    resolve();
                } else {
                    reject();
                }
            } catch (err) {
                reject(err);
            } finally {
                document.body.removeChild(area);
            }
        });
    }

    function showToast(message) {
        toastEl.textContent = message;
        toastEl.hidden = false;
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () {
            toastEl.hidden = true;
        }, 1600);
    }

    function copyValue(text) {
        copyText(text).then(
            function () { showToast('Copied to clipboard'); },
            function () { showToast('Copy failed'); }
        );
    }

    function renderResults(ip) {
        networkValue.textContent = ip.cidr();
        networkValue.dataset.copy = ip.cidr();

        resultsEl.textContent = '';
        ip.results().forEach(function (row) {
            var tile = document.createElement('button');
            tile.type = 'button';
            tile.className = 'result' + (row.key === 'binary' || row.key === 'class' ? ' wide ' + row.key : '');
            tile.dataset.copy = row.value;

            var label = document.createElement('span');
            label.className = 'result-label';
            label.textContent = row.label;

            var value = document.createElement('span');
            value.className = 'result-value';
            value.textContent = row.value;

            tile.appendChild(label);
            tile.appendChild(value);
            resultsEl.appendChild(tile);
        });
    }

    function clearResults() {
        networkValue.textContent = '';
        networkValue.dataset.copy = '';
        resultsEl.textContent = '';
    }

    function update() {
        var octetsOk = true;
        var octets = octetInputs.map(function (input) {
            var text = input.value.trim();
            var ok = isOctet(text);
            setInvalid(input, !ok);
            octetsOk = octetsOk && ok;
            return Number(text);
        });

        var prefixText = prefixInput.value.trim();
        var prefixOk = isPrefix(prefixText);
        setInvalid(prefixInput, !prefixOk);

        if (prefixOk) {
            prefixRange.value = prefixText;
            prefixRange.style.setProperty('--fill', (Number(prefixText) / 32 * 100) + '%');
        }

        if (!octetsOk) {
            showError('Each octet must be a number from 0 to 255.');
            clearResults();
            return;
        }
        if (!prefixOk) {
            showError('The prefix must be a number from 0 to 32.');
            clearResults();
            return;
        }

        clearError();
        renderResults(new IPv4(octets, Number(prefixText)));
    }

    /** Fill all fields from text such as "10.0.0.1/8" or "10.0.0.1". */
    function fillFromText(text) {
        var match = /^\s*(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?:\/(\d{1,2}))?\s*$/.exec(text);
        if (!match) {
            return false;
        }
        for (var i = 0; i < 4; i++) {
            octetInputs[i].value = match[i + 1];
        }
        if (match[5] !== undefined) {
            prefixInput.value = match[5];
        }
        return true;
    }

    octetInputs.forEach(function (input, index) {
        input.addEventListener('input', function () {
            var digits = input.value.replace(/[^\d.]/g, '');
            if (digits !== input.value) {
                input.value = digits;
            }
            var dot = input.value.indexOf('.');
            if (dot !== -1) {
                input.value = input.value.slice(0, dot);
                focusNext(index);
            } else if (input.value.length === 3) {
                focusNext(index);
            }
            update();
        });

        input.addEventListener('keydown', function (event) {
            if (event.key === '.') {
                event.preventDefault();
                focusNext(index);
            } else if (event.key === '/') {
                event.preventDefault();
                prefixInput.focus();
                prefixInput.select();
            } else if (event.key === 'Backspace' && input.value === '' && index > 0) {
                event.preventDefault();
                octetInputs[index - 1].focus();
            }
        });

        input.addEventListener('focus', function () {
            input.select();
        });

        input.addEventListener('paste', function (event) {
            var text = (event.clipboardData || window.clipboardData).getData('text');
            if (fillFromText(text)) {
                event.preventDefault();
                update();
            }
        });
    });

    function focusNext(index) {
        if (index < 3) {
            octetInputs[index + 1].focus();
        } else {
            prefixInput.focus();
        }
    }

    prefixInput.addEventListener('input', update);

    prefixRange.addEventListener('input', function () {
        prefixInput.value = prefixRange.value;
        update();
    });

    prefixInput.addEventListener('focus', function () {
        prefixInput.select();
    });

    prefixInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            octetInputs[0].focus();
        }
    });

    document.getElementById('calc-form').addEventListener('submit', function (event) {
        event.preventDefault();
        update();
    });

    /* Copy a value when its tile is tapped. */
    document.getElementById('calculator').addEventListener('click', function (event) {
        var target = event.target.closest('[data-copy]');
        if (target && target.dataset.copy) {
            copyValue(target.dataset.copy);
        }
    });

    update();
})();
