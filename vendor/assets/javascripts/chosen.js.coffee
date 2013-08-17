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
          if @multiple
            new Chosen.Multiple($this, options)
          else
            new Chosen.Single($this, options)
        ).trigger("chosen:ready")
    )
})

$(window).bind("resize", (evt) ->
  for chosen in Chosen.pool
    chosen.update_dropdown_position() if chosen.opened

  return
)

$(window).bind("scroll", (evt) ->
  for chosen in Chosen.pool
    chosen.close() if chosen.opened

  return
)
