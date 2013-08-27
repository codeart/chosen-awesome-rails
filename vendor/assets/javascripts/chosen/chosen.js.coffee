$ = jQuery

class Chosen
  constructor: (@$target, options = {}) ->
    $.extend(@, $.extend($.extend($.extend({}, Chosen.defaults), @constructor.defaults), options))

    @$body = $("body")
    @target = @$target[0]
    @parser = new Chosen.Parser(@)

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

    if @target.disabled
      @disabled = false
      @disable()
    else
      @disabled = true
      @enable()

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

    width = if @width? then @width else "#{@target.offsetWidth}px"

    container_props =
      class: classes.join ' '
      style: "width: #{width}; min-width: #{width}; max-width: #{width}"

    container_props.title = @target.title if @target.title.length
    container_props.id = @target.id.replace(/[^\w]/g, '-') + "-chosen" if @target.id
    placeholder = @$target.attr("placeholder") || @placeholder

    @$container = $("<div />", container_props)
    @$container.html "<ul class=\"chosen-choices\"><li class=\"chosen-search-field\"><input type=\"text\" placeholder=\"#{placeholder}\" autocomplete=\"off\" /></li></ul>"
    @$container.$choices = @$container.find("ul.chosen-choices")
    @$container.$search_container = @$container.$choices.find("li.chosen-search-field")
    @$container.$search = @$container.$choices.find("input[type=text]").attr(tabindex: @target.tabindex || "0")

    @$dropdown = $("<div />", class: "chosen-dropdown", unselectable: "on", html: "<ul></ul>")
    @$dropdown.$list = @$dropdown.find("ul").first()
    @$dropdown.$list.$no_results = $("<li />", class: "chosen-option no-results")
    @$dropdown.$list.$start_typing = $("<li />", class: "chosen-option start-typing")
    @$dropdown.$list.$add_new = null

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
    return @

  deactivate: ->
    @$container.$search.trigger("blur")
    return @

  enable: ->
    if @disabled
      @$target.removeAttr("disabled")
      @$container.$search.removeAttr("disabled")
      @$container.removeClass("disabled")
      @$container.find("a").each ->
        $(@).attr(tabindex: @tabindex) if @tabindex

      @bind_events()
      @disabled = false

    return @

  disable: ->
    unless @disabled
      @close()
      @blur()
      @unbind_events()

      @$container.find("a").each( ->
        $link = $(@)

        @tabindex = $link.attr("tabindex")
        $link.attr(tabindex: "-1")
      )

      @$container.addClass("disabled")
      @$container.$search.attr(disabled: "disabled")
      @$target.attr(disabled: "disabled")
      @disabled = true

    return @

  focus: (evt) ->
    return @ if @activated

    @activated = true
    @$container.addClass("focus")

    return @

  blur: (evt) ->
    return @ unless @activated

    @set_default_value()
    @close()
    @activated = false
    @$container.removeClass("focus")

    return @

  open: ->
    return @ if @opened

    @redraw_dropdown()

    @$container.$search.trigger("focus") unless @activated
    @$body.append(@$dropdown)

    @opened = true

    @move_selection_to(@parser.index_of(@cursor_option))

    @$dropdown.bind "mouseover", "li.chosen-option", (evt) => @dropdown_mouseover(evt)
    @$dropdown.bind "mousedown", "li.chosen-option", (evt) => @dropdown_mousedown(evt)

    @$container.addClass("opened")
    @$dropdown.addClass("opened")

    return @

  close: ->
    return @ unless @opened

    @$container.removeClass("opened")
    @$dropdown.removeClass("opened")
    @$dropdown.unbind "mouseover mousedown"
    @$dropdown.remove()
    @opened = false

    return @

  dropdown_mouseover: (evt) ->
    option = @parser.find_by_element(evt.target)

    @move_selection_to(@parser.index_of(option)) if option

    evt.preventDefault()
    evt.stopImmediatePropagation()
    return

  dropdown_mousedown: (evt) ->
    option = @parser.find_by_element(evt.target)

    @select(option) if option

    evt.preventDefault()
    evt.stopImmediatePropagation()
    return

  keydown: (evt) ->
    code = evt.which ? evt.keyCode

    switch code
      when 13
        if @opened
          @select(@cursor_option)
          @move_selection(1) if @is_multiple
        else
          @open()
        evt.preventDefault()
      when 27
        evt.preventDefault()
        evt.stopPropagation()
      when 38, 40
        @open()
        @move_selection(code - 39)
        evt.preventDefault()
      else
        true

    return

  keyup: (evt) ->
    code = evt.which ? evt.keyCode

    return if [9, 13, 16, 38, 40].indexOf(code) >= 0

    if code is 27 and @opened
      @close()
      evt.stopPropagation()
    else
      if @ajax and @filter_has_changed()
        @pull_updates()
      else
        @redraw_dropdown()

      @open()

    return

  redraw_dropdown: (data) ->
    @parser.update(data) unless data is undefined
    changed = @apply_filter()
    @update_dropdown_position()
    @update_dropdown_content()
    @move_selection_to(0) if changed
    return

  update_dropdown_position: ->
    list = @$container.find("ul")
    offsets = list.offset()
    height = list.innerHeight()
    width = list.innerWidth()

    @$dropdown.css
      left: "#{offsets.left}px",
      top: "#{offsets.top + height}px"
      width: "#{width}px"

    return

  update_dropdown_content: ->
    if @allow_insertion and @$container.$search[0].value and not @parser.exact_matches().length
      if @$dropdown.$list.$add_new
        @parser.remove(@$dropdown.$list.$add_new)

      @$dropdown.$list.$add_new = @parser.add(
        value: @$container.$search[0].value
        label: @$container.$search[0].value
      )

      @$dropdown.$list.$add_new.$listed.html("#{@$dropdown.$list.$add_new.value} (<b>new</b>)")
    else if @$dropdown.$list.$add_new
      @parser.remove(@$dropdown.$list.$add_new)
      @$dropdown.$list.$add_new = null

    @$dropdown.$list.html(@parser.to_html())

    return

  apply_filter: ->
    return false unless @filter_has_changed()

    @search_value = @$container.$search[0].value
    @parser.apply_filter(@$container.$search[0].value)

    true

  filter_has_changed: ->
    @search_value isnt @$container.$search[0].value

  move_selection: (dir) ->
    cursor = @parser.index_of(@cursor_option) + dir
    cursor = @parser.available_options.length - 1 if cursor < 0
    cursor = 0 if cursor > @parser.available_options.length - 1

    @move_selection_to(cursor)

    if @cursor_option and @cursor_option.selected and @parser.selectable_options.length
      return @move_selection(dir)

    return @

  move_selection_to: (cursor) ->
    if @cursor_option
      @cursor_option.$listed.removeClass("active")

    @cursor_option = @parser.available_options[cursor]

    return unless @cursor_option

    $element = @cursor_option.$listed.addClass("active")
    top = $element.position().top + $element.height()
    list_height = @$dropdown.height()
    list_scroll = @$dropdown.scrollTop()

    if top >= list_height + list_scroll or list_scroll >= top
      @$dropdown.scrollTop($element.position().top)

    return @

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

  pull_updates: ->
    return @ unless @ajax

    if @pending_request and @pending_request.readyState isnt 4
      @pending_request.abort()

    data =
      query: @$container.$search[0].value

    @pending_request = $.ajax
      url: @ajax.url
      type: @ajax.type or "get"
      dataType: @ajax.dataType or "json"
      data: $.extend(@ajax.data || {}, data)
      async: @ajax.async or true
      xhrFields: @ajax.xhrFields

      beforeSend: (xhr) =>
        @ajax.beforeSend(xhr) if typeof @ajax.beforeSend is "function"
      success: (data) =>
        @redraw_dropdown(data)

    return @

  @is_crappy_browser: (version) ->
    window.navigator.appName == "Microsoft Internet Explorer" and document.documentMode <= version

  @is_supported: ->
    not Chosen.is_crappy_browser(6)

  @defaults:
    allow_insertion: false
    inherit_classes: true
    is_rtl: false
    no_result_text: "No results found"
    start_type_text: "Start typing"

  @pool: []

@Chosen = Chosen
