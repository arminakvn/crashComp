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

  customTimeFormat: (d) ->
    format = d3.time.format.multi([
        [
          ".%L"
          (d) ->
            return d.getMilliseconds()
        ]
        [
          ":%S"
          (d) ->
            return d.getSeconds()
        ]
        [
          "%I:%M"
          (d) ->
            return d.getMinutes()
        ]
        [
          "%I %p"
          (d) ->
            return d.getHours()
        ]
        [
          "%a %d"
          (d) ->
            return d.getDay() and d.getDate() isnt 1
        ]
        [
          "%b %d"
          (d) ->
            return d.getDate() isnt 1
        ]
        [
          "%B"
          (d) ->
            return d.getMonth()
        ]
        [
          "%Y"
          ->
            return true
        ]
      ])
    return format(d)

  removeAnyLocation: ->
    d3.select(@_m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
    .data([]).exit().remove()

  _projectPoint: (x) ->
      point = @_m.latLngToLayerPoint(new L.LatLng(x[1], x[0]))
      [
        point.x
        point.y
      ]

  getDirectionsFromGoogle: (featureGroup) ->

  setViewByLocation: (d)-> 
    @_m.setView(new L.LatLng(d.lat, d.long), 19, animation: true, duration: 50)

  showLocation: (d) ->
    featureData =[]
    featureData.push new L.LatLng(d.coordinates.latitude, d.coordinates.longitude)
    @_g = d3.select(@_m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
    @_g.data(featureData).enter().append("g").append("circle").attr("r", 0
    ).attr("stroke", "white"
    ).attr("fill", "none"
    ).attr("stroke-width", "10"
    ).attr("cx", (d) =>
      return @_m.latLngToLayerPoint(d).x
    ).attr("cy", (d) =>
      return @_m.latLngToLayerPoint(d).y
    ).transition().delay(120).duration(1000).attr("r", 80
    ).attr("stroke", "gray"
    ).attr("stroke-width", "0"
    ).attr("fill", "none")

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
    @_g.data(featureData).enter().append("g").append("circle").attr("r", 0
    ).attr("stroke", "white"
    ).attr("fill", "none"
    ).attr("stroke-width", "10"
    ).attr("cx", (d) =>
      return @_m.latLngToLayerPoint(d).x
    ).attr("cy", (d) =>
      return @_m.latLngToLayerPoint(d).y
    ).transition().delay(120).duration(1000).attr("r", 80
    ).attr("stroke", "gray"
    ).attr("stroke-width", "10"
    ).attr("fill", "none")
    return @_g
    

  makeHeatMap: (d)->
    @_m.removeLayer @_heat if @_heat
    monthNameFormat = d3.time.format("%B")
    console.log d
    draw = true
    # _this._m._initPathRoot()
    coordinates = []
    for key, value of @text
      try
        coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) if monthNameFormat(new Date(d3.time.format.iso.parse value.date_time)) == monthNameFormat(d.x)
      catch e
        coordinates.push new L.LatLng(value.address.latitude, value.address.longitude) if monthNameFormat(new Date(d3.time.format.iso.parse value.date_time)) == monthNameFormat(d.x)
      
    @_heat = L.heatLayer(coordinates,
      maxZoom: 16
    )
    @_heat.addTo(@_m)
    # @_heat.addLatLng coordinates 
    timeout = undefined
    @_viewSet = @_m.getCenter() if @_viewSet is undefined
    @_zoomSet = @_m.getZoom() if @_viewZoom is undefined
    @_m.on "load", ->
        # _this._m._initPathRoot()
        # coordinates = []
        # coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) for key, value of @text
        # # @_heat = L.heatLayer(coordinates,
        # #   maxZoom: 18
        # # )
        # # @_heat.addTo(_this._m)
        # # _this._m.setView(new L.LatLng(d.coordinates.latitude, d.coordinates.longitude), 14, animation: true, duration: 500)
        # return @_heat => L.heatLayer(coordinates).addTo(_this._m)
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

  makeDiv: (name, position) ->
    divControl = L.Control.extend(  
      initialize: =>

        _domEl = L.DomUtil.create('div', "container " + name + "-info")
        # _domEl.addClass position
        # _el = L.DomUtil.create('svg', 'svg')
        # @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].appendChild(_el)
        L.DomUtil.enableTextSelection(_domEl)  
        @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].appendChild(_domEl)
        _domObj = $(L.DomUtil.get(_domEl))
        _domObj.css('width', $(@_m.getContainer())[0].clientWidth)
        _domObj.css('height', $(@_m.getContainer())[0].clientHeight/4)
        _domObj.css('background-color', 'gray')
        # _domObj.css('overflow', 'scroll')
        L.DomUtil.setOpacity(L.DomUtil.get(_domEl), 0.8)
        # here it needs to check to see if there is any vewSet avalable if not it should get it from the lates instance or somethign
        L.DomUtil.setPosition(L.DomUtil.get(_domEl), L.point(0, $(@_m.getContainer())[0].clientHeight/2 + $(@_m.getContainer())[0].clientHeight/4), disable3D=0)
        # @_d3El = d3.select("." + name + "-info")
    )
    new divControl()
    
      
  addControlToDiv: (controlerDiv) ->
    console.log @text
    controlerDivEl = @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].getElementsByClassName("container "+controlerDiv+"-info")[0]
    layerSwitchForm = L.DomUtil.create("form")
    layerSwitchInput = L.DomUtil.create("input", "layerSwitch", layerSwitchForm)
    $(layerSwitchInput).attr("type", "button")
    $(layerSwitchInput).attr("position", "absolute")
    $(layerSwitchInput).attr("top", "0px")
    $(layerSwitchInput).attr("right", "0px")
    $(layerSwitchInput).attr("name", "layerSwitch")
    $(layerSwitchInput).attr("value", "By Object1")
    L.DomEvent.addListener layerSwitchInput, 'click', (e) =>
            # e.preventDefault()
            # e.stopPropagation()
            # queue().defer(d3.json, "https://data.cambridgema.gov/resource/vydm-qk5p.json").await (err, data) ->
            #   _this.makeHeatMap(data)
            #   _this.makeLayerController()
            #   return 
    layerSwitchInputRem = L.DomUtil.create("input", "layerSwitch", layerSwitchForm)
    $(layerSwitchInputRem).attr("type", "button")
    $(layerSwitchInputRem).attr("name", "layerSwitchRem")
    $(layerSwitchInputRem).attr("value", "remove")
    controlerDivEl.appendChild(layerSwitchForm)
    L.DomEvent.addListener layerSwitchInputRem, 'click', (e) =>
            e.preventDefault()
            e.stopPropagation()
            [first, ..., last] = @_m._layers
  
  # addLayerFromSODA: (sodaurl) ->
    # geojsonLayer = new L.GeoJSON.AJAX(sodaurl).addTo @_m
    # geojsonLayer.onAdd (map) ->
    
    # L.Util.ajax(sodaurl).then (data) ->
    #   onFulfilled: data 

  makeLayerController: ->
    L.control.layers(
      "Base Map": L.mapbox.tileLayer("arminavn.ib1f592g").addTo(@_m)
      "Open Street": L.mapbox.tileLayer("arminavn.jl495p2g")
    ,
      # "Neighborhoods": omnivore.kml('Cambridge Neighborhood Polygons.kml').addTo(@_m)
      # "Bike Lanes": L.mapbox.tileLayer("examples.bike-lanes")
    ).addTo @_m
    # neighborhoods = L.geoJson("neighborhoods.geojson",
    #   # style: getStyle
    #   # onEachFeature: onEachFeature
    # ).addTo(@_m)
  makeSlider: ->
    @makeDiv {position: "topright", className: "container slider-info"}

  loadLayer: (layer)->
    geojsonLayer = new L.GeoJSON.AJAX(layer)
    geojsonLayer.onAdd (map) ->
    return 

  showPathDirection: (map)->
    featureGroup = L.featureGroup().addTo(map)

    # Define circle options
    # http://leafletjs.com/reference.html#circle
    circle_options =
      color: "#fff" # Stroke color
      opacity: 1 # Stroke opacity
      weight: 10 # Stroke weight
      fillColor: "#000" # Fill color
      fillOpacity: 0.6 # Fill opacity


    # Create array of lat,lon points

    # Define polyline options
    # http://leafletjs.com/reference.html#polyline
    polyline_options = color: "#000"

    # Defining a polygon here instead of a polyline will connect the
    # endpoints and fill the path.
    # http://leafletjs.com/reference.html#polygon
     # textControl = L.Control.extend(
    drawControl = new L.Control.Draw(
      position: "topright"
      edit:
        featureGroup: featureGroup
    )
    map.on "draw:created", (e) =>
      featureGroup.addLayer e.layer
      type = e.layerType
      layer = e.layer
      latLngs = undefined
      if type is "circle"
        latLngs = layer.getLatLng()
      else if type is "marker"
        latLngs = layer._latlng
      else # Returns an array of the points in the path.
        latLngs = layer.getLatLngs()
      @getDirectionsFromGoogle(latLngs)
      return
    drawControl

  groupBy: ->
    monthNameFormat = d3.time.format("%B")
    features = @_geoJson.features.map( (d) ->
      return new Date(d3.time.format.iso.parse(d.properties.date_time))
      )
    nest = d3.nest().key((d) ->
      monthNameFormat(d)
    # ).key((d) ->
    #   d.properties.day_of_week
    ).rollup((d) ->
      d.length
    ).entries(features)
    
    return nest


# data = d3.nest().key((d) ->
#   d.date
# ).rollup((d) ->
#   d3.sum d, (g) ->
#     g.value

# ).entries(csv_data)

  timeserries: ->
    # get the DOM container if not exist make it
    counts = @groupBy()
    all_dates = []
    values = []
    d3.map(counts).forEach (index, value) => 
      values.push(value.values)
      all_dates.push(value.key)
    
    months = []
      
    all_dates.shift()
    values.shift()
    all_dates.shift()
    values.shift()
    all_dates.unshift "x"
    values.unshift "Accident Frequency"
    
    try
        container = L.DomUtil.get(document.getElementsByClassName("container control-info")[0])
    catch e
      @makeDiv("control", "bottomleft")
      container = L.DomUtil.get(document.getElementsByClassName("container control-info")[0])
    margin =
      top: 5
      right: 5
      bottom: 40
      left: 45
    width = 960 - margin.left - margin.right
    height = 80
    d3.select(container).append("div").attr("id", "chart")
    console.log values, all_dates
    chart = c3.generate(
      data:
        onmouseover: (d, element) => @makeHeatMap(d)
        x: "x"
        xFormat: "%B"
        columns: [
          all_dates
          values
          
          #            ['x', '20130101', '20130102', '20130103', '20130104', '20130105', '20130106'],
        ]

      axis:
        x:
          type: "timeseries"
          tick:
            format: d3.time.format("%B")
      size:
        height: $(@_m.getContainer())[0].clientHeight/4
        width: $(@_m.getContainer())[0].clientWidth - 100
    )
    setTimeout (->
      chart.load columns: [
        # values
      ]
      return
    ), 1000
    # d3.selectAll
    # chart = @timeseries(all_dates).x(get_time).xLabel("Time").y(get_magnitude).yLabel("Frequency").brushmove(on_brush)    
    # d3.select("body").datum(@_geoJson.features).call chart
    # series = d3.select(container).append("svg").attr("id", "accidents-timeseries").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("id", "date-brush").attr("transform", "translate(" + margin.left + "," + margin.top + ")")
    
    
    map = @_m



    L.pointsLayer(@_geoJson,
      # radius: get_radius
      applyStyle: @_circle_style
    ).addTo map 
    # chart = timeseries_chart(scheme).x(get_time).xLabel("Earthquake origin time").y(get_magnitude).yLabel("Magnitude").brushmove(on_brush)
    # d3.select("body").datum(@_geoJson.features).call chart

  # timeseries: (selection) ->
  #     selection.each (d) ->
  #       x.range [
  #         0
  #         width
  #       ]
  #       y.range [
  #         height
  #         0
  #       ]
        
  #       x_axis = series.append("g").attr("class", "x axis").attr("transform", "translate(0," + height + ")")
  #       y_axis = series.append("g").attr("class", "y axis")
  #       x_axis.append("text").attr("class", "label").attr("x", width).attr("y", 30).style("text-anchor", "end").text x_label
  #       y_axis.append("text").attr("class", "label").attr("transform", "rotate(-90)").attr("y", -40).attr("dy", ".71em").style("text-anchor", "end").text y_label
  #       series.append("clipPath").attr("id", "clip").append("rect").attr("width", width - 1).attr("height", height - .25).attr "transform", "translate(1,0)"
  #       series.append("g").attr("class", "brush").call(brush).selectAll("rect").attr("height", height).style("stroke-width", 1).style("stroke", color[color.length - 1]).style("fill", color[2]).attr "opacity", 0.4
  #       x.domain d3.extent(d, get_x)
  #       x_axis.call d3.svg.axis().scale(x).orient("bottom")
  #       y.domain d3.extent(d, get_y)
  #       y_axis.call d3.svg.axis().scale(y).orient("left")
  #       series.append("g").attr("class", "timeseries").attr("clip-path", "url(#clip)").selectAll("circle").data(d).enter().append("circle").style("stroke", color[color.length - 2]).style("stroke-width", .5).style("fill", color[color.length - 1]).attr("opacity", .4).attr("r", 2).attr "transform", (d) ->
  #         "translate(" + x(get_x(d)) + "," + y(get_y(d)) + ")"

    

  #       _brushmove = ->
  #         brushmove.call null, brush
  #         return
  #       no_op = ->
  #       timeseries.x = (accessor) ->
  #         return get_x  unless arguments.length
  #         get_x = accessor
  #         timeseries

  #       timeseries.y = (accessor) ->
  #         return get_y  unless arguments.length
  #         get_y = accessor
  #         timeseries

  #       timeseries.xLabel = (label) ->
  #         return x_label  unless arguments.length
  #         x_label = label
  #         timeseries

  #       timeseries.yLabel = (label) ->
  #         return y_label  unless arguments.length
  #         y_label = label
  #         timeseries

  #       timeseries.brushmove = (cb) ->
  #         return brushmove  unless arguments.length
  #         brushmove = cb
  #         timeseries
        
  #       x = d3.time.scale()
  #       y = d3.scale.linear()
  #       x_label = "X"
  #       y_label = "Y"
  #       # brush = d3.svg.brush().x(x).on("brush", _brushmove)
  #       get_x = no_op
  #       get_y = no_op

  #       # reduced = all_dates.reduce (previousValue, currentValue, index, array) =>
  #       #   return


        
  #       x = d3.time.scale()
  #       y = d3.scale.linear()
  #       get_time = (d) ->
  #         d3.time.format.iso.parse d.date_time
  #       # extent = d3.extent(all_dates)
  #       # x.domain(extent)


  _circle_style: (circles) ->
    # unless extent and scale
    #   extent = d3.extent(circles.data(), (d) ->
    #     d.properties.depth
    #   )
    #   scale = d3.scale.log().domain((if reverse then extent.reverse() else extent)).range(d3.range(classes))
    circles.attr("opacity", 0.4).attr("stroke", 1).attr("stroke-width", 1).attr "fill", "red"
      

    # circles.on "click", (d, i) ->
    #   L.DomEvent.stopPropagation d3.event
    #   t = "<h3><%- id %></h3>" + "<ul>" + "<li>Magnitude: <%- mag %></li>" + "<li>Depth: <%- depth %>km</li>" + "</ul>"
    #   data =
    #     id: d.id
    #     mag: d.properties.magnitude
    #     depth: d.properties.depth

    #   L.popup().setLatLng([
    #     d.geometry.coordinates[1]
    #     d.geometry.coordinates[0]
    #   ]).setContent(_.template(t, data)).openOn map
    #   return

    return

  parseGeoJson: ->
    @_geoJson =
      type: "FeatureCollection"
      features: [
        type: "Feature"
        geometry:
          type: "Point"
          coordinates: [
            0.0
            0.0
          ]

        properties:
          prop0: "value0"
      ]
    for each in @text
      @_geoJson.features.push {"type": "Feature", "geometry":{"type": "point", "coordinates": [+each.coordinates.longitude, +each.coordinates.latitude]}, "properties": each} if each.coordinates.latitude isnt "0"


  makeMap: ->
    map = $("body").append("<div id='map'></div>")
    L.mapbox.accessToken = "pk.eyJ1IjoiYXJtaW5hdm4iLCJhIjoiSTFteE9EOCJ9.iDzgmNaITa0-q-H_jw1lJw"
    @_m = L.mapbox.map("map",
      zoomAnimation: true
      zoomAnimationThreshold: 4
      inertiaDeceleration: 4000
      animate: true
      duration: 1.75
      easeLinearity: 0.1
      ).setView([
      42.36653483201389
      -71.12146908569336
    ], 13)
    @makeLayerController()
    # @_m.dragging.disable()
    # @makeHeatMap()
    @_m.boxZoom.enable()
    @_m.scrollWheelZoom.disable()
    # @makeHeatMap()
    # @makeD3onMap()
    drawControl = @showPathDirection(@_m)
    # drawControl.addTo @_m
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
            e.preventDefault()
            e.stopPropagation()
            _this._m.setView(new L.LatLng(d.coordinates.latitude, d.coordinates.longitude), 19, animation: true, duration: 50)
          L.DomEvent.addListener @_leafletli, 'mouseout', (e) ->
            e.preventDefault()
            e.stopPropagation()
            timeout = 0
            @_g = d3.select(_this._m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
            data = []
            # data.push d.coordinates
            @_g.data(data).exit().remove()

          L.DomEvent.addListener @_leafletli, 'mouseover', (e) ->
            e.preventDefault()
            e.stopPropagation()
            $(this).css('cursor','pointer')
            L.stamp _this._leafletli
            timeout = setTimeout(->
              _this._m._initPathRoot()
              if timeout isnt 0 
                _this.removeAnyLocation()
                _this.showLocation(d)
                timeout = 0
            , 800)
            return 
          , ->
            return
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

    # 
  
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
  paratext.parseGeoJson()
  d3onmap = paratext.makeD3onMap()
  control = paratext.makeDiv("control", "bottomleft")
  timeserries = paratext.timeserries()

  timeout = undefined
timeout = 0
      
    
# update()
# $('input').change update

