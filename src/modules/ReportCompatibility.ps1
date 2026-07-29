$script:ProxyScopeOriginalWriteHtmlReport = ${function:Write-HtmlReport}

function Write-HtmlReport {
    param(
        [string]$Path,
        [hashtable]$Data
    )

    & $script:ProxyScopeOriginalWriteHtmlReport -Path $Path -Data $Data

    $html = [System.IO.File]::ReadAllText($Path)

    $html = $html.Replace(
        "  backdrop-filter: blur(12px);",
        "  backdrop-filter: blur(12px);`r`n  z-index: 50;`r`n  pointer-events: auto;"
    )

    $html = $html.Replace(
        '<button type="button" class="language-button active" data-language="en">English</button>',
        '<button type="button" class="language-button active" data-language="en" aria-pressed="true" onclick="if(window.ProxyScopeSetLanguage){window.ProxyScopeSetLanguage(''en'');} return false;">English</button>'
    )

    $html = $html.Replace(
        '<button type="button" class="language-button" data-language="zh">中文</button>',
        '<button type="button" class="language-button" data-language="zh" aria-pressed="false" onclick="if(window.ProxyScopeSetLanguage){window.ProxyScopeSetLanguage(''zh'');} return false;">中文</button>'
    )

    $replacementScript = @'
<script>
(function () {
  var storageKey = "proxyscope-report-language";

  function getLanguageButtons() {
    var allButtons = document.getElementsByTagName("button");
    var languageButtons = [];
    var index;

    for (index = 0; index < allButtons.length; index += 1) {
      if (allButtons[index].getAttribute("data-language")) {
        languageButtons.push(allButtons[index]);
      }
    }

    return languageButtons;
  }

  function setElementText(element, value) {
    if (typeof element.textContent !== "undefined") {
      element.textContent = value;
    }
    else {
      element.innerText = value;
    }
  }

  function setActiveButton(button, active) {
    var className = button.className || "";
    className = className.replace(/\s*active\b/g, "");

    if (active) {
      className += " active";
    }

    button.className = className.replace(/^\s+|\s+$/g, "");
    button.setAttribute("aria-pressed", active ? "true" : "false");
  }

  function applyLanguage(language) {
    var selected = language === "zh" ? "zh" : "en";
    var attribute = selected === "zh" ? "data-zh" : "data-en";
    var allElements = document.getElementsByTagName("*");
    var buttons = getLanguageButtons();
    var index;
    var translatedValue;

    document.documentElement.lang = selected === "zh" ? "zh-CN" : "en";
    document.title = selected === "zh" ? "ProxyScope 诊断报告" : "ProxyScope Report";

    for (index = 0; index < allElements.length; index += 1) {
      if (
        allElements[index].getAttribute("data-en") !== null &&
        allElements[index].getAttribute("data-zh") !== null
      ) {
        translatedValue = allElements[index].getAttribute(attribute);
        setElementText(allElements[index], translatedValue || "");
      }
    }

    for (index = 0; index < buttons.length; index += 1) {
      setActiveButton(buttons[index], buttons[index].getAttribute("data-language") === selected);
    }

    try {
      window.localStorage.setItem(storageKey, selected);
    }
    catch (error) {
    }

    return false;
  }

  window.ProxyScopeSetLanguage = applyLanguage;

  var initialLanguage = "en";

  try {
    var savedLanguage = window.localStorage.getItem(storageKey);

    if (savedLanguage === "en" || savedLanguage === "zh") {
      initialLanguage = savedLanguage;
    }
  }
  catch (error) {
  }

  applyLanguage(initialLanguage);
})();
</script>
'@

    $scriptStart = $html.LastIndexOf("<script>")
    $scriptEnd = if ($scriptStart -ge 0) {
        $html.IndexOf("</script>", $scriptStart)
    }
    else {
        -1
    }

    if ($scriptStart -ge 0 -and $scriptEnd -ge $scriptStart) {
        $scriptEnd += "</script>".Length
        $html = $html.Substring(0, $scriptStart) + $replacementScript + $html.Substring($scriptEnd)
    }

    [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
}
