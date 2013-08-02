$ = jQuery

class Chosen
  constructor: (@target, options = {}) ->
    $.extend(@, $.extend($.extend($.extend({}, Chosen.defaults), @constructor.defaults), options))

    @$target = $(@target)
    @$body = $("body")
    @parser = new Chosen.Parser(@$target)

    @allow_deselect = @is_multiple or (@parser.includes_blank() and @allow_deselect != false)
    @activated = false
    @opened = false

    @search_value = ""
    @cursor_option = null
    @pending_request = null

    @build()
    @load()
    @complete()

  complete: ->
    Chosen.pool.push(@)

    if @$target[0].disabled
      @disable()
    else
      @bind_events()

    @$target.hide().after(@$container)

  destroy: ->
    @unbind_events()

    delete @$body

    @$container.remove()
    @$dropdown.remove()
    @$target.removeData("chosen").show()

    delete @$container
    delete @$dropdown
    delete @$target
    delete @target

    @parser.destroy()

    delete @parser

    index = Chosen.pool.indexOf(@)
    Chosen.pool.splice(index, 1) if index >= 0

  build: ->
    classes = ["chosen-container"]

    classes.push if @is_multiple then "multiple" else "single"
    classes.push "rtl" if @is_rtl
    classes.push @target.className if @inherit_classes and @target.className

    container_props =
      class: classes.join ' '
      style: "width: #{if @width? then @width else "#{@target.offsetWidth}px"};"

    container_props.title = @target.title if @target.title.length
    container_props.id = @target.id.replace(/[^\w]/g, '-') + "-chosen" if @target.id.length
    placeholder = @$target.attr("placeholder") || @placeholder

    @$container = $("<div />", container_props)
    @$container.html "<ul class=\"chosen-choices\"><li class=\"chosen-search-field\"><input type=\"text\" placeholder=\"#{placeholder}\" autocomplete=\"off\" /></li></ul>"
    @$container.$choices = @$container.find("ul.chosen-choices")
    @$container.$search_container = @$container.$choices.find("li.chosen-search-field")
    @$container.$search = @$container.$choices.find("input[type=text]").attr(tabindex: @target.tabindex || "0")

    @$dropdown = $("<div class=\"chosen-dropdown\"><ul></ul></div>")
    @$dropdown.$list = @$dropdown.find("ul").first()

  bind_events: ->
    if @target.id.length
      $("label[for=#{@target.id}]").bind "click", (evt) =>
        @$container.$search.trigger("focus")
        @open()
        evt.preventDefault()

    @$container.bind "mousedown", (evt) =>
      @$container.$search.trigger("focus")
      @open()
      evt.preventDefault()

    @$container.$search.bind "mousedown", (evt) =>
      @$container.$search.trigger("focus")
      @open()
      evt.stopImmediatePropagation()

    @$container.$search.bind "keydown", (evt) => @keydown(evt)
    @$container.$search.bind "keyup", (evt) => @keyup(evt)
    @$container.$search.bind "focus", (evt) => @focus(evt)
    @$container.$search.bind "blur", (evt) => @blur(evt)

    return true

  unbind_events: ->
    if @target.id.length
      $("label[for=#{@target.id}]").unbind "click"

    @$dropdown.unbind()
    @$container.$search.unbind()
    @$container.unbind()

    return true

  activate: ->
    @$container.$search.trigger("focus")

    return true

  deactivate: ->
    @$container.$search.trigger("blur")

    return true

  enable: ->
    @$container.removeClass("disabled")
    @$container.$search[0].disabled = false
    @$container.find("a").each(-> $(@).attr(tabindex: @tabindex))

    @bind_events()

    return true

  disable: ->
    @close()
    @unbind_events()

    @$container.find("a").each( ->
      $link = $(@)

      @tabindex = $link.attr("tabindex")
      $link.attr(tabindex: "-1")
    )

    @$container.$search[0].disabled = true
    @$container.addClass("disabled")

    return true

  focus: (evt) ->
    return if @activated

    @activated = true
    @$container.addClass("focus")

  blur: (evt) ->
    return unless @activated

    @set_default_value()
    @close()
    @activated = false
    @$container.removeClass("focus")

  open: ->
    return false if @opened

    @redraw_dropdown()

    @$container.$search.trigger("focus") unless @activated
    @$body.append(@$dropdown)

    @opened = true

    @move_cursor_to(@parser.index_for(@cursor_option))

    @$dropdown.bind "mouseover", "li.chosen-option", (evt) => @dropdown_mouseover(evt)
    @$dropdown.bind "mousedown", "li.chosen-option", (evt) => @dropdown_mousedown(evt)

    return true

  close: ->
    return false unless @opened

    @$dropdown.unbind "mouseover mousedown"
    @$dropdown.remove()
    @opened = false

    return true

  dropdown_mouseover: (evt) ->
    option = @parser.find_by_element(evt.target)

    @move_cursor_to(@parser.index_for(option)) if option

    evt.preventDefault()
    evt.stopPropagation()

  dropdown_mousedown: (evt) ->
    option = @parser.find_by_element(evt.target)

    @select(option) if option

    evt.preventDefault()
    evt.stopPropagation()

  keydown: (evt) ->
    code = evt.which ? evt.keyCode

    switch code
      when 13
        if @opened
          @select(@cursor_option)
          @move_cursor(1) if @is_multiple
        else
          @open()
        evt.preventDefault()
      when 27
        @close()
        evt.preventDefault()
      when 38, 40
        @open()
        @move_cursor(code - 39)
        evt.preventDefault()
      else
        true

    return

  keyup: (evt) ->
    code = evt.which ? evt.keyCode

    return if [9, 13, 16, 27, 38, 40].indexOf(code) >= 0

    if @ajax
      @get_updates()
    else
      @redraw_dropdown()

    @open()

  redraw_dropdown: (data) ->
    @parser.update(data) unless data is undefined
    @apply_filter()
    @update_dropdown_position()
    @update_dropdown_content()

  apply_filter: ->
    return if @search_value is @$container.$search[0].value

    @move_cursor_to(0)

    @search_value = @$container.$search[0].value
    @parser.apply_filter(@$container.$search[0].value)

  update_dropdown_position: ->
    list = @$container.find("ul")
    offsets = list.offset()
    height = list.innerHeight()
    width = list.innerWidth()

    @$dropdown.css
      left: "#{offsets.left}px",
      top: "#{offsets.top + height}px"
      width: "#{width}px"

  update_dropdown_content: ->
    @$dropdown.$list.html(@parser.to_html())

  move_cursor: (dir) ->
    cursor = @parser.index_for(@cursor_option) + dir
    cursor = @parser.visible_options.length - 1 if cursor < 0
    cursor = 0 if cursor > @parser.visible_options.length - 1

    @move_cursor_to(cursor)

  move_cursor_to: (position) ->
    if @cursor_option
      @cursor_option.$listed.removeClass("active")

    @cursor_option = @parser.visible_options[position]

    return unless @cursor_option

    $element = @cursor_option.$listed.addClass("active")
    top = $element.position().top + $element.height()
    list_height = @$dropdown.height()
    list_scroll = @$dropdown.scrollTop()

    if top >= list_height + list_scroll or list_scroll >= top
      @$dropdown.scrollTop($element.position().top)

  get_caret_position: ->
    field = @$container.$search[0]

    if document.selection
      sel = document.selection.createRange()
      length = sel.text.length

      sel.moveStart('character', -field.value.length)

      sel.text.length - length
    else if field.selectionStart or field.selectionStart is '0'
      field.selectionStart
    else
      0

  get_updates: ->
    if @pending_request and this.pending_request.readyState isnt 4
      @pending_request.abort()

    data =
      query: @$container.$search[0].value

    @pending_request = $.ajax(
      url: @ajax.url
      type: @ajax.type or "get"
      dataType: @ajax.dataType or "json"
      data: $.extend(@ajax.data || {}, data)
      async: @ajax.async or true
      success: (data) =>
        @redraw_dropdown(data)
    )

  @is_crappy_browser: (version) ->
    window.navigator.appName == "Microsoft Internet Explorer" and document.documentMode <= version

  @is_supported: ->
    not Chosen.is_crappy_browser(6)

  @defaults:
    inherit_classes: true
    is_rtl: false
    no_result_text: "No results found"
    start_type_text: "Start typing"

  @pool: []

@Chosen = Chosen
