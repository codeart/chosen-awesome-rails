$ = jQuery

class Chosen.Single extends Chosen
  build: ->
    super

    if @allow_deselect
      @$container.$reset = $("<a></a>",
        class: "chosen-delete",
        href: "javascript:void(0)",
        tabindex: @target.tabindex || "0"
      )

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

  set_default_value: ->
    selected = @parser.selected()[0]
    @$container.$search[0].value = if selected then selected.label else ""

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
