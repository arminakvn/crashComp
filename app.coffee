##############
L.ParaText = L.Class.extend(
  initialize: (@text) ->
    @properties=
        id: 0
        members: []
        _margin: 
          t: 20
          l: 30
          b: 30
          r: 30
        relations: {}
        lat: 0
        long: 0
    return
  # addChainedAttributeAccessor(this, 'properties', attr) for attr of @properties

  addTo: (map) ->
    map.addLayer this
    this

  getD3: ->
    @_count = 0
    @_canvas = $(".canvas")
    @_width = @_canvas.width() - @properties._margin.l - @properties._margin.r
    @_height = @_canvas.height() - @properties._margin.t - @properties._margin.b
    @_svg = d3.select(".").append("svg").attr("width", @_width + @properties._margin.l + @properties._margin.r).attr("height", @_height + @properties._margin.t + @properties._margin.b).append("g").attr("transform", "translate(" + @properties._margin.l + "," + @properties._margin.t + ")")
    @_svg.selectAll("text").data(@properties.text).enter().append("text").attr("width", 2400).attr("height", 200)
    .style("font-family", "Impact").attr("fill", "black").text((d) ->
      d.description
    ).on("mouseover", ->
      d3.select(this).transition().duration(300).style "fill", "gray"
      # 
      return
    ).on("mouseout", ->
      d3.select(this).transition().duration(300).style "fill", "black"
      return
    ).transition().delay(0).duration(1).each("start", ->
      d3.select(this).transition().duration(1).attr "y", ((@_count + 1) * 30)
      @_count = @_count + 1
      return
    ).transition().duration(11).delay(1).style "opacity", 1
    @_count = @_count + 1
    return @_svg
  
  makeD3onMap: ->
    @_map = @_m
    @_project = (x) ->
      point = @_map.latLngToLayerPoint(new L.LatLng(x[1], x[0]))
      [
        point.x
        point.y
      ]

    @_el = d3.select(@_map.getPanes().overlayPane).append("svg")
    @_g = @_el.append("g").attr("class", (if @properties.svgClass then @properties.svgClass + " leaflet-zoom-hide" else "leaflet-zoom-hide"))
    featureData =[]
    featureData.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) for key, value of @text # new L.LatLng(d.lat, d.long)
    @_g = d3.select(@_m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
    @_g.data(featureData).enter().append("g").append("circle").attr("r", 60
    ).attr("stroke", "lightcoral"
    ).attr("fill", "none"
    ).attr("cx", (d) =>
      @_m.latLngToLayerPoint(d).x
    ).attr("cy", (d) =>
      @_m.latLngToLayerPoint(d).y
    ).transition().delay(30).duration(1000).attr("r", 4
    ).attr("cx", (d) =>
      return @_m.latLngToLayerPoint(d).x
    ).attr("cy", (d) =>
      return @_m.latLngToLayerPoint(d).y
    ).transition().delay(30).duration(1000).attr("r", 2
    ).attr("stroke", "yellow")
    return @_g
    

  makeHeatMap: ->
    console.log "inside heatmap"
    draw = true
    # _this._m._initPathRoot()
    coordinates = []
    coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) for key, value of @text
    @_heat = L.heatLayer(coordinates,
      maxZoom: 18
    )
    @_heat.addTo(@_m)
    # @_heat.addLatLng coordinates 
    timeout = undefined
    @_viewSet = @_m.getCenter() if @_viewSet is undefined
    @_zoomSet = @_m.getZoom() if @_viewZoom is undefined
    @_m.on "load", ->
        # console.log "inside onload"
        # _this._m._initPathRoot()
        # coordinates = []
        # coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) for key, value of @text
        # # @_heat = L.heatLayer(coordinates,
        # #   maxZoom: 18
        # # )
        # # @_heat.addTo(_this._m)
        # # _this._m.setView(new L.LatLng(d.coordinates.latitude, d.coordinates.longitude), 14, animation: true, duration: 500)
        # console.log "@_heat", @_heat
        # return @_heat => L.heatLayer(coordinates).addTo(_this._m)
      console.log "inside onload"
      return
    @_m.setView (new L.LatLng(@_viewSet.lat, @_viewSet.lng)), @_viewZoom 
    
    
    return
   
    
    @_m.on
      zoomend: =>
        @_m.removeLayer @_heat if @_m.getZoom() > 16
        @_m.addLayer @_heat if @_m.getZoom() < 16
      movestart: ->
        draw = false
        return

      moveend: ->
        draw = true
        return

      mousemove: (e) =>
        return

  makeDiv: (name)->
    _domEl = L.DomUtil.create('div', "." + name + "-info")
    _el = L.DomUtil.create('svg', 'svg')
    @_m.getPanes().overlayPane.appendChild(_el)
    L.DomUtil.enableTextSelection(_domEl)  
    @_m.getPanes().overlayPane.appendChild(_domEl)
    _domObj = $(L.DomUtil.get(_domEl))
    _domObj.css('width', $(@_m.getContainer())[0].clientWidth/3)
    _domObj.css('height', $(@_m.getContainer())[0].clientHeight)
    _domObj.css('background-color', 'white')
    _domObj.css('overflow', 'scroll')
    L.DomUtil.setOpacity(L.DomUtil.get(_domEl), 0.8)
    # here it needs to check to see if there is any vewSet avalable if not it should get it from the lates instance or somethign
    @_viewSet = @_m.getCenter() if @_viewSet is undefined
    L.DomUtil.setPosition(L.DomUtil.get(_domEl), L.point(40, -65), disable3D=0)
    @_d3El = d3.select("." + name + "-info")


  makeSlider: ->
    @makeDiv {position: "topright", className: "container slider-info"}

  makeMap: ->
    map = $("body").append("<div id='map'></div>")
    L.mapbox.accessToken = "pk.eyJ1IjoiYXJtaW5hdm4iLCJhIjoiSTFteE9EOCJ9.iDzgmNaITa0-q-H_jw1lJw"
    @_m = L.mapbox.map("map", "arminavn.ib1f592g",
      zoomAnimation: true
      zoomAnimationThreshold: 4
      inertiaDeceleration: 4000
      animate: true
      duration: 1.75
      easeLinearity: 0.1
      ).setView([
      42.36653483201389
      -71.12146908569336
    ], 15)
    # @_m.dragging.disable()
    # @makeHeatMap()
    @_m.boxZoom.enable()
    @_m.scrollWheelZoom.disable()
    # @makeHeatMap()
    # @makeD3onMap()
    textControl = L.Control.extend(
      options:
        position: "topleft"
      onAdd: (map) =>
        @_m = map  
          # create the control container with a particular class name

        @_textDomEl = L.DomUtil.create('div', 'container paratext-info')
        @_el = L.DomUtil.create('svg', 'svg')
        @_m.getPanes().overlayPane.appendChild(@_el)
        L.DomUtil.enableTextSelection(@_textDomEl)  
        @_m.getPanes().overlayPane.appendChild(@_textDomEl)
        @_textDomObj = $(L.DomUtil.get(@_textDomEl))
        @_textDomObj.css('width', $(@_m.getContainer())[0].clientWidth/4)
        @_textDomObj.css('height', $(@_m.getContainer())[0].clientHeight)
        @_textDomObj.css('background-color', 'white')
        @_textDomObj.css('overflow', 'scroll')
        L.DomUtil.setOpacity(L.DomUtil.get(@_textDomEl), 0.8)
        # here it needs to check to see if there is any vewSet avalable if not it should get it from the lates instance or somethign
        @_viewSet = @_m.getCenter() if @_viewSet is undefined
        L.DomUtil.setPosition(L.DomUtil.get(@_textDomEl), L.point(40, -65), disable3D=0)
        @_d3text = d3.select(".paratext-info")
        .append("ul").style("list-style-type", "none").style("padding-left", "0px")
        .attr("width", $(@_m.getContainer())[0].clientWidth/4)
        .attr("height", $(@_m.getContainer())[0].clientHeight-80)
        @_d3li = @_d3text
        .selectAll("li")
        .data(@text)
        .enter()
        .append("li")
        @_d3li.style("font-family", "Helvetica")
        .style("line-height", "2")
        .style("margin-top", "10px")
        .style("padding-right", "20px")
        .style("padding-left", "40px")
        .attr("id", (d, i) =>
           "line-#{i}" 
          )
        .text((d,i) =>
          @_leafletli = L.DomUtil.get("line-#{i}")
          timeout = undefined
          L.DomEvent.addListener @_leafletli, 'click', (e) ->
            _this._m.setView(new L.LatLng(d.coordinates.latitude, d.coordinates.longitude), 19, animation: true, duration: 50)
          L.DomEvent.addListener @_leafletli, 'mouseout', (e) ->
            @_g = d3.select(_this._m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
            data = []
            # data.push d.coordinates
            @_g.data(data).exit().remove()

          L.DomEvent.addListener @_leafletli, 'mouseover', (e) ->
            $(this).css('cursor','pointer')
            L.stamp _this._leafletli
            timeout = setTimeout(->
              _this._m._initPathRoot()
              featureData =[]
              featureData.push new L.LatLng(d.coordinates.latitude, d.coordinates.longitude) #val for key, val of d # new L.LatLng(d.lat, d.long)
              @_g = d3.select(_this._m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
              @_g.data(featureData).enter().append("g").append("circle").attr("r", 60
              ).attr("stroke", "lightcoral"
              ).attr("fill", "none"
              ).attr("cx", (d) ->
                _this._m.latLngToLayerPoint(d).x
              ).attr("cy", (d) ->
                _this._m.latLngToLayerPoint(d).y
              ).transition().delay(30).duration(1000).attr("r", 4
              ).attr("cx", (d) ->
                return _this._m.latLngToLayerPoint(d).x
              ).attr("cy", (d) ->
                return _this._m.latLngToLayerPoint(d).y
              ).transition().delay(30).duration(1000).attr("r", 2
              ).attr("stroke", "yellow"
              ).attr("stroke-width", "5"
              ).attr("fill", "none")
              # _this._m.setView(new L.LatLng(d.coordinates.latitude, d.coordinates.longitude), 14, animation: true, duration: 500)
            , 5)
            return
          , ->
            return
          clearTimeout timeout
          d.date_time 
        )
        .style("font-size", "16px")
        .style("color", "rgb(72,72,72)" )
        .on("mouseover", (d,i) ->
          $(this).css('cursor','pointer')
          d3.select(this).transition().duration(0).style("color", "black").style("background-color", "rgb(208,208,208) ").style "opacity", 1
          return 
        ).on("mouseout", (d,i) ->
          d3.select(this).transition().duration(1000).style("color", "rgb(72,72,72)").style("background-color", "white").style "opacity", 1
          return
        )  
        .transition().duration(1).delay(1).style("opacity", 1)
        @_m.whenReady =>
        timeout = undefined
        L.stamp @_leafletli
    
        _this._m._initPathRoot()
     
        @_textDomEl


    )

    @_m.addControl new textControl()
  
    return @_m

  connectRelation: ->
    @raw_text = @properties.text
  )
L.paratext = (text) ->
  new L.ParaText(text)

addChainedAttributeAccessor = (obj, propertyAttr, attr) ->
    obj[attr] = (newValues...) ->
        if newValues.length == 0
            obj[propertyAttr][attr]
        else
            obj[propertyAttr][attr] = newValues[0]
            obj

##########
#################
queue().defer(d3.json, "https://data.cambridgema.gov/resource/ybny-g9cv.json").await (err, texts) ->
  draw texts
  return

draw = (data) ->
  paratext = L.paratext(data)
  textmap = paratext.makeMap()
  heatmap = paratext.makeHeatMap()
  # d3onmap = paratext.makeD3onMap()
  texts = d3.selectAll("li")
  testdiv = paratext.makeDiv("testdiv")
  L.DomUtil.create

  # bding the L.D3 to jQuery and assiging data from and to datum
  $texts = $(texts[0])
  $texts.each ->
    $(this).data "datum", $(this).prop("__data__")
    return
  # jQuery handles the clicks
  timeout = undefined

# update()
# $('input').change update

