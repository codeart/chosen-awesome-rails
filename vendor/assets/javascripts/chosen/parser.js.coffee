$ = jQuery

class Chosen.Parser
  constructor: (@$target)->
    @all_options = []
    @visible_options = []

    @parse()

  destroy: ->
    delete @all_options
    delete @visible_options
    delete @$target
    return

  parse: (selected_options = []) ->
    current_group_label = null
    group = null

    @$target.find("option").each (index, option) =>
      if option.parentNode.nodeName is "OPTGROUP"
        if current_group_label != option.parentNode.label
          current_group_label = option.parentNode.label
          group = $("<li class=\"chosen-group\">#{current_group_label}</li>")
      else
        group = null

      classes = ["chosen-option"]
      classes.push "group" if group
      classes.push "selected" if option.selected
      classes.push "disabled" if option.disabled

      selected = $.grep(selected_options, (o, i) =>
        o.value is option.value and o.label is option.label)[0]

      @all_options.push
        $group: group
        $listed: (selected and selected.$listed) or $("<li class=\"#{classes.join(' ')}\">#{option.text || "&nbsp;"}</li>")
        $choice: (selected and selected.$choise) or $("<li class=\"#{classes.join(' ')}\"><a href=\"javascript:void(0)\" class=\"chosen-delete\" tabindex=\"#{@$target[0].tabindex || "0"}\"></a>#{option.text || "&nbsp;"}</li>")
        $option: (selected and selected.$option) or $(option)
        blank: option.value is "" and index is 0
        index: index
        score: index * -1
        label: option.text
        value: option.value
        selected: option.selected
        disabled: option.disabled

    @order()

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
        @$target.append("<option value=\"#{attrs.value}\">#{attrs.label}</option>")

    @parse(selected_options)

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
    return unless option

    option.$option[0].selected = true
    option.$option.attr(selected: "selected")
    option.$listed.addClass("selected")
    option.$choice.addClass("selected")
    option.selected = true

    return

  deselect: (option) ->
    return unless option

    option.$option[0].selected = false
    option.$option.removeAttr("selected")
    option.$listed.removeClass("selected")
    option.$choice.removeClass("selected")
    option.selected = false

    return

  select_all: ->
    for option in @all_options
      @select(option)

  deselect_all: ->
    for option in @all_options
      @deselect(option)

  selected: ->
    $.grep @all_options, (option) ->
      option and option.selected

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

  reset_filter: ->
    option.score = option.index * -1 for option in @all_options
    return

  order: ->
    @all_options = @all_options.sort (a, b) ->
      if a.score > b.score then -1 else if a.score < b.score then 1 else 0

    @visible_options = []

    for option in @all_options
      if not option.blank
        @visible_options.push(option)

    return

  @escape: /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g
