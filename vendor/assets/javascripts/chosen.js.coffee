#= require chosen/chosen
#= require chosen/multiple
#= require chosen/single
#= require chosen/parser

$ = jQuery

$.fn.extend({
  chosen: (options) ->
    return @ unless Chosen.is_supported()

    @each(->
      $this = $(@)

      unless $this.data("chosen")
        $this.data('chosen',
          if @multiple then new Chosen.Multiple(@, options) else new Chosen.Single(@, options))
    )
})

$(window).bind("resize", (evt) ->
  for chosen in Chosen.pool
    if chosen.opened
      chosen.update_dropdown_position()
)
