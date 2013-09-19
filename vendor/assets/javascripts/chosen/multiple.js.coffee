$ = jQuery

class Chosen.Multiple extends Chosen
  constructor: ->
    super

    @pending_option = null

  bind_option_events: (option) ->
    option.$choice.find("a").unbind().
      bind("mousedown", -> false).
      bind("click", (evt) => @deselect_choice(evt))
    return

  set_default_value: ->
    @$container.$search[0].value = ""
    return

  dropdown_mousedown: ->
    @reset_pending_option()
    super
    return

  keydown: (evt) ->
    code = evt.which ? evt.keyCode

    unless code is 8
      @reset_pending_option()

    switch code
      when 8
        @set_pending_option(true) if @pending_option
      else
        super

    return

  keyup: (evt) ->
    code = evt.which ? evt.keyCode

    if code is 8
      @set_pending_option(false)
    else
      @reset_pending_option()

    super

  set_pending_option: (do_deselect) ->
    if @pending_option and do_deselect
      @deselect(@pending_option)
      @reset_pending_option()

    return if @get_caret_position() > 0 and @$container.$search[0].value.length

    choise = @$container.$choices.find("li.chosen-option").last()[0]
    option = @parser.find_by_element(choise)
    return unless option

    unless @pending_option
      option.$choice.addClass("active")
      @pending_option = option

    return

  reset_pending_option: ->
    if @pending_option
      @pending_option.$choice.removeClass("active")
      @pending_option = null

    return

  deselect_choice: (evt) ->
    option = @parser.find_by_element(evt.target.parentNode)

    $choice = $(evt.target.parentNode)
    $next = $choice.next("li.chosen-option")
    $prev = $choice.prev("li.chosen-option")
    $sibling = if $next.length then $next else if $prev.length then $prev else null

    @deselect(option) if option

    if $sibling and not @activated
      $sibling.find("a").trigger("focus")
    else
      @activate()

    evt.preventDefault()
    evt.stopPropagation()

    return @

  deselect: (option) ->
    @parser.deselect(option)

    option.$choice.remove()
    @update_dropdown_position()

    @$target.trigger("change")
    return @

  select: (option) ->
    return @ if not option or option.disabled or option.selected

    @parser.select(option)
    @$container.$search_container.before(option.$choice)

    @$container.$search[0].value = ""

    @bind_option_events(option)
    @close()

    @$target.trigger("change")
    return @

  deselect_all: ->
    for option in @parser.selected()
      @deselect(option)

    return @

  select_all: ->
    for option in @parser.not_selected()
      @select(option)

    return @

  load: ->
    for option in @parser.selected()
      @bind_option_events(option)
      @$container.$search_container.before(option.$choice)

    return @

  @defaults:
    is_multiple: true
    placeholder: "Select some options"
