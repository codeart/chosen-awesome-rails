$ = jQuery

class Chosen.Parser
  constructor: (@chosen)->
    @all_options = []
    @visible_options = []

    @parse()

  destroy: ->
    delete @all_options
    delete @visible_options
    delete @chosen
    return

  parse: (selected_options = []) ->
    current_group_label = null
    group = null

    link_params =
      html: "×"
      href: "javascript:void(0)"
      class: "chosen-delete"
      tabindex: @chosen.$target[0].tabindex || "0"

    @chosen.$target.find("option").each (index, option) =>
      if option.parentNode.nodeName is "OPTGROUP"
        if current_group_label != option.parentNode.label
          current_group_label = option.parentNode.label
          group = $("<li class=\"chosen-group\">#{current_group_label}</li>")
      else
        group = null

      classes = "chosen-option"
      classes += " group" if group
      classes += " selected" if option.selected
      classes += " disabled" if option.disabled

      selected = $.grep(selected_options, (o, i) =>
        o.value is option.value and o.label is option.label)[0]

      text = if typeof @chosen.formatter is "function"
        @chosen.formatter(option)
      else
        [option.text, option.text]

      @all_options.push
        $group: group
        $listed: (selected and selected.$listed) or $("<li />", class: classes, html: text[0])
        $choice: (selected and selected.$choise) or $("<li />", class: classes, html: [$("<a />", link_params), text[1]])
        $option: (selected and selected.$option) or $(option)
        blank: option.value is "" and index is 0
        index: index
        score: index * -1
        label: option.text
        value: option.value
        selected: option.selected
        disabled: option.disabled

    @order()
    return @

  update: (data) ->
    selected_options = []

    for option in @all_options
      if option.selected or option.blank
        selected_options.push(option)
      else
        option.$option.remove()

    @all_options = []

    for attrs in data
      unless $.grep(selected_options, (o, i) => o.value is attrs.value.toString() and o.label == attrs.label.toString() ).length
        @chosen.$target.append("<option />", value: attrs.value, html: attrs.label, data: { source: attrs })

    @parse(selected_options)
    return @

  to_html: ->
    last_group = null
    list = []

    for option in @visible_options
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

  index_for: (option) ->
    if option then @visible_options.indexOf(option) else 0

  select: (option) ->
    return @ unless option

    option.$option[0].selected = true
    option.$option.attr(selected: "selected")
    option.$listed.addClass("selected")
    option.$choice.addClass("selected")
    option.selected = true

    return @

  deselect: (option) ->
    return @ unless option

    option.$option[0].selected = false
    option.$option.removeAttr("selected")
    option.$listed.removeClass("selected")
    option.$choice.removeClass("selected")
    option.selected = false

    return @

  selected: ->
    $.grep @visible_options, (option) ->
      option and option.selected

  not_selected: ->
    $.grep @visible_options, (option) ->
      option and not option.selected

  includes_blank: ->
    not not @blank_option()

  blank_option: ->
    for option in @all_options
      return option if option.blank

    return null

  apply_filter: (value) ->
    @reset_filter()

    length = @all_options.length

    if $.trim(value).length
      expressions = $.map(value.replace(Parser.escape, "\\$&").split(" "), (word, index) ->
        return [[
          new RegExp(word, "i")
          new RegExp("^#{word}", "i")
          new RegExp("^#{word}$", "i")
        ]]
      )

      for option in @all_options
        words = option.label.split(" ")

        for word in words
          for exp in expressions
            exact = word.match(exp[2])
            begin = if exact then false else word.match(exp[1])
            sub = if begin then false else word.match(exp[0])

            option.score +=
              if exact then length * 10 else if begin then length * 5 else if sub then length else -1

    @order()
    return @

  reset_filter: ->
    option.score = option.index * -1 for option in @all_options
    return @

  order: ->
    @all_options = @all_options.sort (a, b) ->
      if a.score > b.score then -1 else if a.score < b.score then 1 else 0

    @visible_options = []

    for option in @all_options
      if not option.blank
        @visible_options.push(option)

    return @

  @escape: /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g
