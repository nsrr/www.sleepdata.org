@setScrollShadow = (element) ->
  return unless $(element)[0]
  scroll = $(element).scrollTop();
  if scroll + $(element).innerHeight() == $(element)[0].scrollHeight
    $(element).removeClass("shadow-inset-bottom")
  else
    $(element).addClass("shadow-inset-bottom")

  if scroll == 0
    $(element).removeClass("shadow-inset-top")
  else
    $(element).addClass("shadow-inset-top")

@setFocusToField = (element_id) ->
  val = $(element_id).val()
  $(element_id).focus().val('').val(val)

@initializeTypeahead = () ->
  $('[data-object~="typeahead"]').each( () ->
    $this = $(this)
    $this.typeahead(
      local: $this.data('local')
    )
  )

@ready = () ->
  contourReady()
  $('.file-list-container').scroll( () ->
    setScrollShadow(this)
  )
  setScrollShadow($('.file-list-container'))
  $("[rel=tooltip]").tooltip( trigger: 'hover' )
  if $("#collection_form #s, #page_name, #search_form #s, #search, #collection_form #s, #s").val() != ''
    setFocusToField("#collection_form #s, #page_name, #search_form #s, #search, #collection_form #s, #s")
  $("img.lazy").lazyload( effect : "fadeIn" )
  Turbolinks.allowLinkExtensions('md')
  Turbolinks.enableProgressBar()
  window.$isDirty = false
  prettyPrint()
  variablesReady() if (typeof variablesReady == 'function')
  datasetsReady()
  agreementsReady()
  commentsReady()
  tagsReady()
  downloadGraphsReady()
  showcaseReady()
  mapsReady()
  challengesReady()
  initializeTypeahead()
  new WOW().init()

$(window).onbeforeunload = () -> return "You haven't saved your changes." if window.$isDirty
$(document).ready(ready)
$(document)
  .on('page:load', ready)
  .on('page:before-change', -> confirm("You haven't saved your changes.") if window.$isDirty)
  .on('click', '[data-object~="submit"]', () ->
    window.$isDirty = false
    $($(this).data('target')).submit()
    false
  )
  .on('click', '[data-object~="list-submit"]', () ->
    $('#view').val('list')
    $($(this).data('target')).submit()
    false
  )
  .on('click', '[data-object~="grid-submit"]', () ->
    $('#view').val('')
    $($(this).data('target')).submit()
    false
  )
  .on('click', '[data-object~="commonly-used-submit"]', () ->
    $('#common').val($(this).data('value'))
    $($(this).data('target')).submit()
    false
  )
  .on('click', "[data-basename]", () ->
    $.get(root_url + 'collection_modal', { "basename": $(this).data('basename'), slug: $(this).data('slug'), d: $(this).data('d') }, null, "script")
    return false
  )
  .on('click', '[data-object~="hide-target"]', () ->
    $($(this).data('target')).hide()
    false
  )
  .on('click', '[data-object~="show-target"]', () ->
    $($(this).data('target')).show()
    false
  )
  .on('click', '[data-object~="disable-target"]', () ->
    $($(this).data('input-target')).prop('disabled', true);
  )
  .on('click', '[data-object~="enable-target"]', () ->
    $($(this).data('input-target')).prop('disabled', false);
  )
  .on('click', '[data-object~="agreement-update"]', () ->
    $("#email-comments-container").hide()
    $("#approval-date-container, #expiration-date-container").show()
    $("#agreement_approval_date, #agreement_expiration_date").prop('disabled', false);
  )
  .on('click', '[data-object~="agreement-resubmit"]', () ->
    $("#email-comments-container").show()
    $("#approval-date-container, #expiration-date-container").hide()
    $("#agreement_approval_date, #agreement_expiration_date").prop('disabled', true);
  )
