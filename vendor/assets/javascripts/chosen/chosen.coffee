$ = jQuery

class Chosen
  constructor: (@$target, options = {}) ->
    $.extend(@, $.extend($.extend($.extend({}, Chosen.defaults), @constructor.defaults), options))

    @$body = $("body")
    @$window = $(window)
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
    @refresh()

    Chosen.pool.push(@)

    @$target.before(@$container)
      .on("change chosen:update", (evt, data) => @refresh(evt, data))

  destroy: ->
    @destroyed = true
    @$target.unbind "change chosen:update"

    @unbind_events()

    delete @$body

    @$container.remove()
    @$dropdown.remove()
    @$target.removeData("chosen").removeClass("chosen").show()

    if @$container.$search[0].required
      @target.required = true

    delete @$container
    delete @$dropdown
    delete @$target
    delete @target

    @parser.destroy()

    delete @parser

    index = Chosen.pool.indexOf(@)
    Chosen.pool.splice(index, 1) if index >= 0

  build: ->
    # TODO: improve iOS support
    #  * don't pass focus to the search field when clicked (avoid virtual keyboard)
    #  * add "tap for search" placeholder when dropdown is shown
    #  * add "done" button next to the search field so iOS users can hide the virtual keyboard
    is_ios = Chosen.is_ios()
    container_classes = ["chosen-container"]

    container_classes.push "ios" if is_ios
    container_classes.push if @is_multiple then "multiple" else "single"
    container_classes.push "rtl" if @is_rtl
    container_classes.push @target.className if @inherit_classes and @target.className

    container_props =
      class: container_classes.join ' '
      css: if @width then { width: @width } else Chosen.getCSSProperties(@target, ["width", "min-width", "max-width"])

    @$target.addClass("chosen")
    @$target.addClass("ios") if is_ios

    attrs = Chosen.getCSSProperties(@target, ["height"])

    container_props.css['min-height'] = attrs.height if attrs.height
    container_props.title = @target.title if @target.title.length
    container_props.id = @target.id.replace(/[^\w]/g, '-') + "-chosen" if @target.id

    input_attrs =
      autocomplete: "off"
      role:         "presentation"
      tabindex:     @target.tabindex || "0"
      placeholder:  @$target.attr("placeholder") || @placeholder

    if @target.required
      input_attrs.required = @target.required and not @parser.selected().length
      input_attrs["data-required"] = @target.required
      @target.required = false

    dropdown_classes = ["chosen-dropdown"]

    dropdown_classes.push if @is_multiple then "multiple" else "single"
    dropdown_classes.push "rtl" if @is_rtl

    dropdown_props =
      class: dropdown_classes.join ' '
      unselectable: "on"
      html: "<ul></ul>"

    @$container = $("<div />", container_props)
    @$container.html "<ul class=\"chosen-choices\"><li class=\"chosen-search-field\"><input type=\"text\" /></li></ul>"
    @$container.$choices = @$container.find("ul.chosen-choices")
    @$container.$search_container = @$container.$choices.find("li.chosen-search-field")
    @$container.$search = @$container.$choices.find("input[type=text]").attr(input_attrs)

    @$dropdown = $("<div />", dropdown_props)
    @$dropdown.$list = @$dropdown.find("ul").first()
    @$dropdown.$list.$has_more = $("<li />", class: "chosen-hasmore")
    @$dropdown.$list.$no_results = $("<li />", class: "chosen-noresults")
    @$dropdown.$list.suggestion = null

  getCSSProperties: (node, properties) ->
    Chosen.getCSSProperties(arguments...)

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

    @$container.$search.bind "keydown", $.proxy(@keydown, @)
    @$container.$search.bind "keyup",   $.proxy(@keyup, @)
    @$container.$search.bind "focus",   $.proxy(@focus, @)
    @$container.$search.bind "blur",    $.proxy(@blur, @)

    @$target.bind "change", $.proxy(@change, @)

    return true

  unbind_events: ->
    if @target.id.length
      $("label[for=#{@target.id}]").unbind "click"

    @$target.unbind "change", @change

    @$dropdown.unbind()
    @$container.$search.unbind()
    @$container.unbind()

    return true

  reset: ->
    @deselect_all()

    $.each @default_values, (index, option) =>
      @parser.restore(option)

    @load()

  refresh: (evt, data) ->
    # Event triggered inside chosen
    if typeof data is "object" and data.chosen
      return true

    if @target.disabled
      @disabled = false
      @disable()
    else
      @disabled = true
      @enable()

  change: (evt, data) ->
    # Event triggered outside of chosen, sync with external changes
    if not data or not data.chosen
      @parser.sync()

    if @parser.selected().length
      @$container.$search.removeAttr("required")
    else if @$container.$search.data("required")
      @$container.$search.attr("required", "required")

  required: (value) ->
    @$container.$search.attr
      "required":      value
      "data-required": value

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
    @$dropdown.bind "mousewheel DOMMouseScroll scroll", (evt) => @dropdown_scroll(evt)

    @$container.addClass("opened")
    @$dropdown.addClass("opened")

    return @

  close: ->
    return @ unless @opened

    @$container.removeClass("opened")
    @$dropdown.removeClass("opened")
    @$dropdown.$list.$has_more.unbind()
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
    target = evt.target.closest('li')
    option = @parser.find_by_element(target)

    @select(option) if option

    evt.preventDefault()
    evt.stopImmediatePropagation()
    return

  dropdown_scroll: (evt) ->
    delta  = evt.originalEvent.wheelDelta || -evt.originalEvent.detail
    bottom = @$dropdown.$list[0].scrollHeight - @$dropdown.scrollTop() <= @$dropdown.innerHeight()
    top    = @$dropdown.scrollTop() <= 0
    query  = @$container.$search.val()

    if delta and ((delta < 0 and bottom) or (delta > 0 and top))
      evt.preventDefault()
      evt.stopImmediatePropagation()
    else if delta and delta > 0 and top
      evt.preventDefault()
      evt.stopImmediatePropagation()

    # Try pulling next pages when at bottom
    if bottom && query
      @pull_next_page()

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

  redraw_dropdown: ->
    changed = @apply_filter()

    @update_dropdown_position()
    @update_dropdown_content()
    @move_selection_to(0) if changed

    return

  update_dropdown_position: ->
    return unless @opened

    rect = @$container[0].getBoundingClientRect()
    rect.width  ||= rect.right - rect.left
    rect.height ||= rect.bottom - rect.top

    offsets = @$container.offset()
    offsets.bottom = @$body.height() - (offsets.top + rect.height)

    border_width = parseInt(@$container.css("border-bottom-width"))
    upside = false

    viewport_top    = rect.top;
    viewport_bottom = @$window.height() - rect.bottom;
    viewport_height = viewport_bottom

    if viewport_bottom < 250 and viewport_top > viewport_bottom
      viewport_height = viewport_top
      upside = true

    options =
      top:       "initial"
      bottom:    "initial"
      left:      "#{offsets.left}px"
      width:     "#{rect.width}px"
      maxHeight: "#{(if viewport_height > 300 then 300 else viewport_height) + border_width}px"

    if upside
      @$dropdown.addClass("upside").removeClass("downside")
      @$container.addClass("upside").removeClass("downside")

      options.bottom = "#{offsets.bottom + rect.height - border_width}px"
    else
      @$dropdown.addClass("downside").removeClass("upside")
      @$container.addClass("downside").removeClass("upside")

      options.top = "#{offsets.top + rect.height - border_width}px"

    @$dropdown.css(options)

  update_dropdown_content: ->
    @insert_suggestion()

    if @parser.selectable_options.length
      @$dropdown.$list.html(@parser.to_html())

      if @ajax and @ajax.has_more isnt false
        @show_has_more()
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

  show_has_more: ->
    @$dropdown.$list.$has_more.text(@locale.has_more)
    @$dropdown.$list.append(@$dropdown.$list.$has_more)
    @$dropdown.$list.$has_more.one "click", => @pull_next_page()

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

    if cursor > @parser.available_options.length - 1
      if @ajax and @ajax.has_more isnt false
        # Try pulling next pages
        @pull_next_page(=> @move_selection(dir))

      return @

    return @ if cursor < 0

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
    top = $element.position().top
    bottom = top + $element.outerHeight()
    list_height = @$dropdown.height()
    list_scroll = @$dropdown.scrollTop()

    if bottom >= list_height + list_scroll
      @$dropdown.scrollTop(bottom - list_height)
    else if list_scroll >= top
      @$dropdown.scrollTop(top)

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

    if @ajax.pending_update
      clearTimeout(@ajax.pending_update)

    @ajax.pending_update = setTimeout =>
      if @ajax.pending_update_request and @ajax.pending_update_request.readyState isnt 4
        @ajax.pending_update_request.abort()

      # Reset current page and has_more flag
      delete @ajax.data.page if @ajax.data
      delete @ajax.has_more
      return @ if @destroyed

      data =
        query: @$container.$search.val()

      @ajax.pending_update_request = $.ajax
        url:       @ajax.url
        type:      @ajax.type or "get"
        dataType:  @ajax.dataType or "json"
        data:      $.extend(data, @ajax.data or {})
        async:     @ajax.async or true
        xhrFields: @ajax.xhrFields

        beforeSend: (xhr) =>
          @loading()
          @ajax.beforeSend?(arguments...)
        success: (data) =>
          return if @destroyed
          @loaded()
          @ajax.success?(arguments...)
          @parser.update(data) unless data is undefined
          @redraw_dropdown()
        error: =>
          return if @destroyed
          @error()
          @ajax.error?(arguments...)
        complete: =>
          return if @destroyed
          @ajax.complete?(arguments...)
    , 300

    return @

  pull_next_page: (cb) ->
    return @ unless @ajax and @ajax.has_more isnt false

    if @ajax.pending_next_page_request and @ajax.pending_next_page_request.readyState isnt 4
      return @

    @ajax.data ||= {}
    @ajax.data.page = if @ajax.data.page then @ajax.data.page + 1 else 2

    data =
      query: @$container.$search.val()

    @ajax.pending_next_page_request = $.ajax
      url:       @ajax.url
      type:      @ajax.type or "get"
      dataType:  @ajax.dataType or "json"
      data:      $.extend(data, @ajax.data or {})
      async:     @ajax.async or true
      xhrFields: @ajax.xhrFields

      beforeSend: (xhr) =>
        @loading()
      success: (data) =>
        @loaded()
        @ajax.has_more = !!data.length
        return if @destroyed
        @parser.append(data) unless data is undefined
        @redraw_dropdown()
        cb() if cb
      error: =>
        @ajax.data.page = if @ajax.data.page is 2 then null else @ajax.data.page - 1
        return if @destroyed
        @error()

    return @

  @getCSSProperties: (node, properties) ->
    attrs = {}
    return attrs if Chosen.is_crappy_browser(8)

    matches = []
    sheets = document.styleSheets
    node.matches = node.matches or node.webkitMatchesSelector or
      node.mozMatchesSelector or node.msMatchesSelector or node.oMatchesSelector

    for i of sheets
      try
        rules = sheets[i].rules or sheets[i].cssRules
      catch
        continue

      Chosen.scanCSSRules(node, rules, matches)

    for p in properties
      for m in matches
        match = m.match(new RegExp("(?:\\s|;|^)#{p}:\\s*([^;]+)"))

        if match
          attrs[p] = match[1]

    attrs

  @scanCSSRules: (node, rules, matches) ->
    for r of rules
      try
        switch rules[r].type
          when 1
            if node.matches(rules[r].selectorText)
              matches.push rules[r].cssText
          when 4
            if window.matchMedia and window.matchMedia(rules[r].media.mediaText).matches
              Chosen.scanCSSRules(node, rules[r].rules or rules[r].cssRules, matches)
      catch
        continue

  @is_ios: ->
    /iPad|iPhone|iPod/.test(navigator.userAgent) and not window.MSStream

  @is_crappy_browser: (version) ->
    window.navigator.appName is "Microsoft Internet Explorer" and document.documentMode <= version

  @is_supported: ->
    not Chosen.is_crappy_browser(6)

  @defaults:
    allow_insertion:  false
    inherit_classes:  true
    is_rtl:           false
    option_parser:    null
    option_formatter: null
    locale:
      no_results:   "No results found"
      start_typing: "Please start typing"
      add_new:      "add new"
      has_more:     "Load more options"

  @pool: []

@Chosen = Chosen
