$ = jQuery

class Chosen.Parser
  constructor: (@chosen)->
    @all_options = []
    @available_options = []
    @selected_options = []
    @selectable_options = []

    @parse()

  destroy: ->
    delete @all_options
    delete @available_options
    delete @selected_options
    delete @selectable_options
    delete @chosen
    return

  # Replaces all select options and parses it again
  update: (data) ->
    parser = @chosen.option_parser || @default_parser
    selected_options = []

    for option in @all_options
      if option.selected or option.blank
        selected_options.push(option)
      else
        option.$option.remove()

    for attrs in data
      parsed = parser(attrs)
      value  = parsed.value.toString()
      text   = parsed.text.toString()

      unless $.grep(selected_options, (o) -> o.value is value and o.label is text ).length
        @chosen.$target.append($("<option />", parsed))

    @parse(selected_options)
    return @

  # Appends new options to the end of the list
  append: (data) ->
    parser = @chosen.option_parser || @default_parser

    for attrs in data
      parsed = parser(attrs)
      value  = parsed.value.toString()
      text   = parsed.text.toString()

      unless $.grep(@all_options, (o) -> o.value is value and o.label is text).length
        @insert(attrs, true)

    return @

  parse: (selected_options = []) ->
    formatter = @chosen.option_formatter || @default_formatter

    group       = null
    group_label = null
    group_id    = 0

    @all_options = []
    @selected_options = []
    @selectable_options = []

    $reset_link = @build_reset_link()

    @chosen.$target.find("option").each (index, option) =>
      if option.parentNode.nodeName is "OPTGROUP"
        if group_label != option.parentNode.label
          group_label = option.parentNode.label
          group = $("<li />", class: "chosen-group", text: group_label)
          group.group_id = group_id
          group_id += 1
      else
        group = null

      classes = "chosen-option"
      classes += " group"    if group
      classes += " selected" if option.selected
      classes += " disabled" if option.disabled

      $option = $(option)
      selected = $.grep(selected_options, (o) -> o.value is option.value and o.label is option.label)[0]
      text = formatter($option)

      chosen_option =
        $group:     group
        $listed:    (selected and selected.$listed) or $("<li />", class: classes, html: text[0])
        $choice:    (selected and selected.$choice) or $("<li />", class: classes, html: [$reset_link.clone(), text[1]])
        $option:    (selected and selected.$option) or $option
        blank:      option.value is "" and index is 0
        index:      index
        score:      index * -1
        label:      option.text
        value:      option.value
        selected:   option.selected
        disabled:   option.disabled
        match_type: null

      @all_options.push chosen_option

      unless chosen_option.blank
        @selected_options.push chosen_option if option.selected
        @selectable_options.push chosen_option unless option.selected

    @order()
    return @

  insert: (option, append = false) ->
    $option     = $("<option />", value: option.value, text: option.label)
    $reset_link = @build_reset_link()

    formatter = @chosen.option_formatter || @default_formatter
    text      = formatter($option)
    classes   = "chosen-option"

    @chosen.$target.append($option)

    chosen_option =
      $group:     null
      $listed:    $("<li />", class: classes, html: text[0])
      $choice:    $("<li />", class: classes, html: [$reset_link, text[1]])
      $option:    $option
      blank:      false
      index:      0
      score:      0
      label:      $option[0].text
      value:      $option[0].value
      selected:   false
      disabled:   false
      match_type: if append then null else -1

    if append
      @all_options.push chosen_option
      @available_options.push chosen_option
      @selectable_options.push chosen_option
    else
      @all_options.unshift chosen_option
      @available_options.unshift chosen_option
      @selectable_options.unshift chosen_option

    chosen_option

  restore: (option) ->
    @select(option)

    unless $.grep(@all_options, (o) -> option.label is o.label).length
      @chosen.$target.append(option.$option)

      @all_options.unshift option
      @available_options.unshift option
      @selectable_options.unshift option

    @parse()

  remove: (option) ->
    return if option.selected

    option.$listed.remove()
    option.$choice.remove()
    option.$option.remove()

    for collection in [@all_options, @available_options, @selected_options, @selectable_options]
      index = collection.indexOf(option)
      collection.splice(index, 1) if index > -1

  sync: ->
    for option in @all_options
      if option.$option[0].selected and @selected_options.indexOf(option) < 0
        @chosen.select(option, false)
      else if not option.$option[0].selected and @selected_options.indexOf(option) >= 0
        @chosen.deselect(option, false)

  to_html: ->
    last_group = null
    list = []

    for option in @available_options
      if option.$group
        if not last_group or (last_group and last_group.text() isnt option.$group.text())
          last_group = option.$group.clone()
          list.push last_group
      else
        last_group = null

      list.push option.$listed

    list

  find_by_element: (element) ->
    for option in @all_options
      if option.$listed[0] is element or option.$choice[0] is element
        return option

    return null

  index_of: (option) ->
    if option then @available_options.indexOf(option) else 0

  select: (option) ->
    return @ unless option

    option.$option.prop(selected: true)
    option.$listed.addClass("selected")
    option.$choice.addClass("selected")
    option.selected = true

    if (index = @selectable_options.indexOf(option)) >= 0
      @selectable_options.splice(index, 1)

    @selected_options.push(option)

    return @

  deselect: (option) ->
    return @ unless option

    option.$option.prop(selected: false)
    option.$listed.removeClass("selected")
    option.$choice.removeClass("selected")
    option.selected = false

    if (index = @selected_options.indexOf(option)) >= 0
      @selected_options.splice(index, 1)

    @selectable_options.push(option)

    return @

  selected: ->
    $.grep @available_options, (option) ->
      option.selected

  not_selected: ->
    $.grep @available_options, (option) ->
      not option.selected

  exact_matches: ->
    $.grep @available_options, (option) ->
      option.match_type is -1

  includes_blank: ->
    not not @blank_option()

  blank_option: ->
    for option in @all_options
      return option if option.blank

    return null

  reset_filter: ->
    option.score = option.index * -1 for option in @all_options
    return @

  apply_filter: (value) ->
    @reset_filter()

    if (value = $.trim(value))
      num_options = @all_options.length
      exact_query = value.toLowerCase()
      query       = $.grep(exact_query.replace(Parser.escape_exp, "\\$&").split(/\W/), (s) -> s.length)

      expressions_collection = $.map(query, (w, i) ->
        return [[new RegExp("^#{w}$", "i"), new RegExp("^#{w}", "i"), new RegExp(w, "i")]]
      )

      for option in @all_options
        option.score = 0

        if option.label.toLowerCase() is exact_query
          option.match_type = -1
        else
          option.match_type = null

        words = $.grep(option.label.split(/\W/), (s) -> s.length)

        for word, word_index in words
          for expressions in expressions_collection
            for expression, expression_index in expressions
              if word.match(expression)
                unless option.match_type is -1
                  option.match_type = expression_index

                option.score += num_options * (expressions.length - option.match_type) / (word_index + 1)
                break
              else if expression_index is expressions.length - 1
                option.score -= num_options * expressions.length / words.length

    @order()
    return @

  # Re-order all_options array keeping the optgroup order
  order: ->
    groups = {}

    for option in @all_options
      group_id = if option.$group then option.$group.group_id else -1
      groups[group_id] ||= []
      groups[group_id].push(option)

    @all_options       = []
    @available_options = []

    for own group_id, value of groups
      @all_options = @all_options.concat(@order_group(value))

    for option in @all_options
      if not option.blank
        @available_options.push(option)

    return @

  order_group: (group) ->
    group
      .sort (a, b) -> a.index - b.index
      .sort (a, b) -> b.score - a.score

  default_parser: (attrs) ->
    value: attrs.value
    text:  attrs.label
    data:  { source: attrs }

  default_formatter: ($option) ->
    value = $option.contents().text()
    [value, value]

  build_reset_link: ->
    $("<a />",
      text: "×"
      href: "javascript:void(0)"
      class: "chosen-delete"
      tabindex: @chosen.$target[0].tabindex || "0"
    )

  @escape_exp: /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g
