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

  bind_events: ->
    super

    if @allow_deselect
      @$container.$reset.bind "mousedown", (evt) ->
        evt.stopImmediatePropagation()
        evt.preventDefault()

      @$container.$reset.bind "click", (evt) =>
        @deselect()
        @load()
        evt.stopImmediatePropagation()

  unbind_events: ->
    super

    if @allow_deselect
      @$container.$reset.unbind()

  set_default_value: ->
    selected = @parser.selected()[0]
    @$container.$search[0].value = if selected then selected.label else ""

    if selected and not selected.blank
      @$container.removeClass("placeholder")
    else
      @$container.addClass("placeholder")

  deselect: (option) ->
    @parser.deselect_all()

    @close() if @opened
    @activate()

    @$target.trigger("change")

  select: (option) ->
    return false if not option or option.disabled or option.selected

    @parser.deselect_all()
    @parser.select(option)

    @set_default_value()
    @close()

    @$target.trigger("change")

  load: ->
    @set_default_value()

  @defaults:
    is_multiple: false
    placeholder: "Select an option"
