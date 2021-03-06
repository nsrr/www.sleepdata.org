@clipboardReady = ->
  clipboard = new Clipboard('[data-clipboard-target],[data-clipboard-text]')
  clipboard.on('success', (e) ->
    $(e.trigger).tooltip('show')
    setTimeout(
      () -> $(e.trigger).tooltip("dispose"),
      1000
    )
    e.clearSelection()
  )
