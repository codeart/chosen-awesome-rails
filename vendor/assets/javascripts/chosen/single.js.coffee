$ = jQuery

class Chosen.Single extends Chosen
  build: ->
    super

    if @allow_deselect
      @$container.$reset = @parser.build_reset_link()
      @$container.append(@$container.$reset)

    return

  bind_events: ->
    super

    if @allow_deselect
      @$container.$reset.bind "mousedown", (evt) ->
        evt.stopImmediatePropagation()
        evt.preventDefault()

      @$container.$reset.bind "click", (evt) =>
        @deselect()
        @load()
        @activate()
        evt.stopImmediatePropagation()

    return

  unbind_events: ->
    super

    if @allow_deselect
      @$container.$reset.unbind()

    return

  open: ->
    return @ if @opened

    selected = @parser.selected()[0]

    if selected and @$container.$search[0].value is selected.label
      @$container.$search[0].value = ""

    super

  set_default_value: ->
    selected = @parser.selected()[0]
    @$container.$search[0].value = if selected then selected.label else ""
    @$container.$search[0].defaultValue = @$container.$search[0].value

    if selected and not selected.blank
      @$container.removeClass("placeholder")
    else
      @$container.addClass("placeholder")

    return

  deselect: (option) ->
    @parser.deselect(option || @parser.selected()[0])

    @set_default_value()
    @close()

    @$target.trigger("change")
    return @

  select: (option) ->
    return @ if not option or option.disabled or option.selected

    @parser.deselect(@parser.selected()[0])
    @parser.select(option)

    @set_default_value()
    @close()

    @$target.trigger("change")
    return @

  deselect_all: ->
    @deselect()
    return @

  select_all: ->
    return @

  load: ->
    @set_default_value()
    return @

  @defaults:
    is_multiple: false
    placeholder: "Select an option"
