$ = jQuery

class Chosen
  constructor: (@$target, options = {}) ->
    $.extend(@, $.extend($.extend($.extend({}, Chosen.defaults), @constructor.defaults), options))

    @$body = $("body")
    @target = @$target[0]
    @parser = new Chosen.Parser(@)
    @default_values = $.map @parser.selected_options, (option) -> option

    @allow_deselect = @is_multiple or (@parser.includes_blank() and @allow_deselect != false)
    @activated = false
    @opened = false

    @search_value = ""
    @cursor_option = null

    @build()
    @load()

    Chosen.pool.push(@)

    @set_state()

    @$target.addClass("chosen").after(@$container).bind("chosen:update", (evt) => @set_state())

  destroy: ->
    @$target.unbind "chosen:update"

    @unbind_events()

    delete @$body

    @$container.remove()
    @$dropdown.remove()
    @$target.removeData("chosen").removeClass("chosen").show()

    delete @$container
    delete @$dropdown
    delete @$target
    delete @target

    @parser.destroy()

    delete @parser

    index = Chosen.pool.indexOf(@)
    Chosen.pool.splice(index, 1) if index >= 0

  set_state: ->
    if @target.disabled
      @disabled = false
      @disable()
    else
      @disabled = true
      @enable()

  reset: ->
    @deselect_all()

    $.each @default_values, (index, option) =>
      @parser.restore(option)

    @load()

  build: ->
    select_classes = ["chosen-container"]

    select_classes.push if @is_multiple then "multiple" else "single"
    select_classes.push "rtl" if @is_rtl
    select_classes.push @target.className if @inherit_classes and @target.className

    container_props =
      class: select_classes.join ' '
      css: if @width? then { width: @width } else @getCSSProperties(@target, ["width", "min-width", "max-width"])

    attrs = @getCSSProperties(@target, ["height"])

    if attrs.height
      container_props.css['min-height'] = attrs.height

    container_props.title = @target.title if @target.title.length
    container_props.id = @target.id.replace(/[^\w]/g, '-') + "-chosen" if @target.id
    placeholder = @$target.attr("placeholder") || @placeholder

    @$container = $("<div />", container_props)
    @$container.html "<ul class=\"chosen-choices\"><li class=\"chosen-search-field\"><input type=\"text\" placeholder=\"#{placeholder}\" autocomplete=\"off\" /></li></ul>"
    @$container.$choices = @$container.find("ul.chosen-choices")
    @$container.$search_container = @$container.$choices.find("li.chosen-search-field")
    @$container.$search = @$container.$choices.find("input[type=text]").attr(tabindex: @target.tabindex || "0")

    dropdown_classes = ["chosen-dropdown"]

    dropdown_classes.push if @is_multiple then "multiple" else "single"
    dropdown_classes.push "rtl" if @is_rtl

    dropdown_props =
      class: dropdown_classes.join ' '
      unselectable: "on"
      html: "<ul></ul>"

    @$dropdown = $("<div />", dropdown_props)
    @$dropdown.$list = @$dropdown.find("ul").first()
    @$dropdown.$list.$no_results = $("<li />", class: "chosen-noresults")
    @$dropdown.$list.suggestion = null

  getCSSProperties: (node, properties)->
    attrs = {}
    return attrs if Chosen.is_crappy_browser(8)

    sheets = document.styleSheets
    node.matches = node.matches or node.webkitMatchesSelector or node.mozMatchesSelector or node.msMatchesSelector or node.oMatchesSelector
    matches = []

    for i of sheets
      rules = sheets[i].rules or sheets[i].cssRules

      for r of rules
        if node.matches(rules[r].selectorText)
          matches.push rules[r].cssText

    for p in properties
      for m in matches
        match = m.match(new RegExp("(?:\\s|;|^)#{p}:\\s*([^;]+)"))

        if match
          attrs[p] = match[1]

    attrs

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

      @$container.find("a").each(->
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

    @opened = true

    @redraw_dropdown()

    @$container.$search.trigger("focus") unless @activated
    @$body.append(@$dropdown)

    @move_selection_to(@parser.index_of(@cursor_option))

    @$dropdown.bind "mouseover", "li.chosen-option", (evt) => @dropdown_mouseover(evt)
    @$dropdown.bind "mousedown", "li.chosen-option", (evt) => @dropdown_mousedown(evt)
    @$dropdown.bind "mousewheel DOMMouseScroll", (evt) => @prevent_page_scroll(evt)

    @$container.addClass("opened")
    @$dropdown.addClass("opened")

    return @

  close: ->
    return @ unless @opened

    @$container.removeClass("opened")
    @$dropdown.removeClass("opened")
    @$dropdown.unbind "mouseover mousedown mousewheel DOMMouseScroll"
    @$dropdown.remove()
    @opened = false

    return @

  loading: ->
    @loaded()
    @$container.addClass("loading")
    @$dropdown.addClass("loading")
    return @

  loaded: ->
    @$container.removeClass("loading error")
    @$dropdown.removeClass("loading error")
    return @

  error: ->
    @loaded()
    @$container.addClass("error")
    @$dropdown.addClass("error")
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

  prevent_page_scroll: (evt) ->
    delta = evt.originalEvent.wheelDelta || -evt.originalEvent.detail

    if (delta < 0 and @$dropdown.$list[0].scrollHeight - @$dropdown.scrollTop() == @$dropdown.innerHeight()) or (delta > 0 and @$dropdown.scrollTop() == 0)
      evt.preventDefault()

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

    return if [9, 13, 16, 35, 36, 37, 38, 39, 40].indexOf(code) >= 0

    if code is 27 and @opened
      @close()
      evt.stopPropagation()
    else if @has_filter_changed()
      @open()

      if @ajax then @pull_updates() else @redraw_dropdown()

    return

  redraw_dropdown: (data) ->
    @parser.update(data) unless data is undefined

    changed = @apply_filter()

    @update_dropdown_position()
    @update_dropdown_content()
    @move_selection_to(0) if changed

    return

  update_dropdown_position: ->
    return unless @opened

    offsets = @$container.offset()
    height = @$container.innerHeight()
    width = @$container.innerWidth()

    @$dropdown.css
      left: "#{offsets.left}px",
      top: "#{offsets.top + height}px"
      width: "#{width}px"

    return

  update_dropdown_content: ->
    @insert_suggestion()

    if @parser.selectable_options.length
      @$dropdown.$list.html(@parser.to_html())
    else
      @show_no_results()

    return

  insert_suggestion: ->
    return unless @allow_insertion

    if @$dropdown.$list.suggestion
      @parser.remove(@$dropdown.$list.suggestion)

    if @$container.$search[0].value and not @parser.exact_matches().length
      @$dropdown.$list.suggestion = suggestion = @parser.insert(
        value: @$container.$search[0].value
        label: @$container.$search[0].value
      )

      value = "#{suggestion.value} (#{@locale.add_new})"

      suggestion.$listed.contents().last()[0].nodeValue = value
      suggestion.$choice.contents().last()[0].nodeValue = value
    else if @$dropdown.$list.suggestion
      @$dropdown.$list.suggestion = null

  show_no_results: ->
    text = if @ajax then @locale.start_typing else @locale.no_results

    @$dropdown.$list.$no_results.text(text)
    @$dropdown.$list.html(@$dropdown.$list.$no_results)

  apply_filter: ->
    return false unless @has_filter_changed()

    @search_value = @$container.$search[0].value
    @parser.apply_filter(@$container.$search[0].value)

    true

  has_filter_changed: ->
    @search_value isnt @$container.$search[0].value

  move_selection: (dir) ->
    cursor = @parser.index_of(@cursor_option) + dir
    cursor = @parser.available_options.length - 1 if cursor < 0
    cursor = 0 if cursor > @parser.available_options.length - 1

    @move_selection_to(cursor)

    if @cursor_option and @cursor_option.selected and @parser.selectable_options.length
      # TODO: optimize this, could be slow on big lists
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
    return @ if not @ajax or not @$container.$search[0].value

    if @ajax.pending_update
      clearTimeout(@ajax.pending_update)

    @ajax.pending_update = setTimeout =>
      if @ajax.pending_request and @ajax.pending_request.readyState isnt 4
        @ajax.pending_request.abort()

      data =
        query: @$container.$search[0].value

      @ajax.pending_request = $.ajax
        url: @ajax.url
        type: @ajax.type or "get"
        dataType: @ajax.dataType or "json"
        data: $.extend(@ajax.data || {}, data)
        async: @ajax.async or true
        xhrFields: @ajax.xhrFields

        beforeSend: (xhr) =>
          @loading()
          @ajax.beforeSend(xhr) if typeof @ajax.beforeSend is "function"
        success: (data) =>
          @loaded()
          @redraw_dropdown(data)
        error: =>
          @error()

    , 300

    return @

  @is_crappy_browser: (version) ->
    window.navigator.appName == "Microsoft Internet Explorer" and document.documentMode <= version

  @is_supported: ->
    not Chosen.is_crappy_browser(6)

  @defaults:
    allow_insertion: false
    inherit_classes: true
    is_rtl: false
    option_parser: null
    option_formatter: null
    locale:
      no_results: "No results found"
      start_typing: "Please start typing"
      add_new: "add new"

  @pool: []

@Chosen = Chosen
