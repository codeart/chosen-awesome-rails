$ = jQuery

class Chosen.Multiple extends Chosen
  constructor: ->
    super

    @pending_option = null

  bind_option_events: (option) ->
    option.$choice.find("a").unbind().
      bind("mousedown", -> false).
      bind("click", (evt) => @deselect_choice(evt))

  set_default_value: ->
    @$container.$search[0].value = ""

  dropdown_mousedown: ->
    @reset_pending_option()
    super

  keydown: (evt) ->
    code = evt.which ? evt.keyCode

    unless code is 8
      @reset_pending_option()

    switch code
      when 8
        @set_pending_option()
      else
        super

    return

  set_pending_option: ->
    if @pending_option
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

    $choise = $(evt.target.parentNode)
    $next = $choise.next("li.chosen-option")
    $prev = $choise.prev("li.chosen-option")
    $sibling = if $next.length then $next else if $prev.length then $prev else null

    @deselect(option) if option

    if $sibling and not @activated
      $sibling.find("a").trigger("focus")
    else
      @activate()

    evt.preventDefault()
    evt.stopPropagation()

  deselect: (option) ->
    @parser.deselect(option)

    option.$choice.remove()

    @update_dropdown_position() if @opened

    @$target.trigger("change")

  select: (option) ->
    return false if not option or option.disabled or option.selected

    @parser.select(option)
    @$container.$search_container.before(option.$choice)

    @bind_option_events(option)
    @update_dropdown_position() if @opened

    @$target.trigger("change")

  load: ->
    for option in @parser.selected()
      @bind_option_events(option)
      @$container.$search_container.before(option.$choice)

  @defaults:
    is_multiple: true
    placeholder: "Select some options"
