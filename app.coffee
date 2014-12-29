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

  formatTime: (d) ->
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
    return format

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
    console.log "indide getDirectionsFromGoogle"
    console.log featureGroup

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
    # @_project = (x) ->
    #   point = @_map.latLngToLayerPoint(new L.LatLng(x[1], x[0]))
    #   [
    #     point.x
    #     point.y
    #   ]

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
    ).attr("stroke-width", "0"
    ).attr("fill", "none")
    return @_g
    

  makeHeatMap: (d)->
    # console.log L
    # console.log "inside heatmap", d
    draw = true
    # _this._m._initPathRoot()
    coordinates = []
    for key, value of d
      try
        coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude)
      catch e
        coordinates.push new L.LatLng(value.address.latitude, value.address.longitude)
      
    # console.log "@_m", @_m
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

  makeDiv: (name, position) ->
    console.log name
    console.log position
    divControl = L.Control.extend(  
      initialize: =>

        _domEl = L.DomUtil.create('div', "container " + name + "-info")
        # _domEl.addClass position
        # _el = L.DomUtil.create('svg', 'svg')
        # @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].appendChild(_el)
        L.DomUtil.enableTextSelection(_domEl)  
        @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].appendChild(_domEl)
        _domObj = $(L.DomUtil.get(_domEl))
        _domObj.css('width', $(@_m.getContainer())[0].clientWidth/3)
        _domObj.css('height', $(@_m.getContainer())[0].clientHeight/4)
        _domObj.css('background-color', 'white')
        # _domObj.css('overflow', 'scroll')
        L.DomUtil.setOpacity(L.DomUtil.get(_domEl), 0.8)
        # here it needs to check to see if there is any vewSet avalable if not it should get it from the lates instance or somethign
        L.DomUtil.setPosition(L.DomUtil.get(_domEl), L.point(540, 0), disable3D=0)
        # @_d3El = d3.select("." + name + "-info")
    )
    new divControl()
    
      
  addControlToDiv: (controlerDiv) ->
    # console.log "controlerDiv", controlerDiv
    controlerDivEl = @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].getElementsByClassName("container "+controlerDiv+"-info")[0]
    # console.log controlerDivEl
    layerSwitchForm = L.DomUtil.create("form")
    layerSwitchInput = L.DomUtil.create("input", "layerSwitch", layerSwitchForm)
    $(layerSwitchInput).attr("type", "button")
    $(layerSwitchInput).attr("name", "layerSwitch")
    $(layerSwitchInput).attr("value", "Bike Path")
    L.DomEvent.addListener layerSwitchInput, 'click', (e) =>
            e.preventDefault()
            e.stopPropagation()
            console.log @
            queue().defer(d3.json, "https://data.cambridgema.gov/resource/vydm-qk5p.json").await (err, data) ->
              console.log data
              _this.makeHeatMap(data)
              console.log _this._m._layers
              _this.makeLayerController()
              return 
    layerSwitchInputRem = L.DomUtil.create("input", "layerSwitch", layerSwitchForm)
    $(layerSwitchInputRem).attr("type", "button")
    $(layerSwitchInputRem).attr("name", "layerSwitchRem")
    $(layerSwitchInputRem).attr("value", "remove")
    controlerDivEl.appendChild(layerSwitchForm)
    L.DomEvent.addListener layerSwitchInputRem, 'click', (e) =>
            e.preventDefault()
            e.stopPropagation()
            [first, ..., last] = @_m._layers
            console.log first
            console.log @_m._layers[0]
            console.log $("#{@_m._layers}:last-child")
  
  # addLayerFromSODA: (sodaurl) ->
    # geojsonLayer = new L.GeoJSON.AJAX(sodaurl).addTo @_m
    # geojsonLayer.onAdd (map) ->
      # console.log "on Add", map
    
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
    console.log layer
    geojsonLayer = new L.GeoJSON.AJAX(layer)
    console.log geojsonLayer
    geojsonLayer.onAdd (map) ->
      console.log "on add"
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
      # console.log featureGroup
      # console.log @
      type = e.layerType
      layer = e.layer
      console.log "e", e
      console.log "layer", layer
      latLngs = undefined
      if type is "circle"
        latLngs = layer.getLatLng()
      else if type is "marker"
        console.log "matker"
        latLngs = layer._latlng
      else # Returns an array of the points in the path.
        latLngs = layer.getLatLngs()
      @getDirectionsFromGoogle(latLngs)
      return
    drawControl

  injectWalkScore: (address, lat, lon) ->
    address = encodeURIComponent(address)
    url = "api-sample-code-get-walkscore.php?address=" + address + "&lat=" + lat + "&lon=" + lon
    $.ajax
      url: url
      type: "GET"
      success: (data) ->
        _this.displayWalkScores data
        return

      error: ->
        _this.displayWalkScores ""
        return

    return

  #to demonstrate all of our formatting options, we'll pass the json on to a series of display functions.
  #in practice, you'll only need one of these, and the ajax call could call it directly as it's onSuccess callback
  displayWalkScores: (jsonStr) ->
    _this.displayWalkScore jsonStr
    return

  #show the walk score -- inserts walkscore html into the page.  Also needs CSS from top of file
  displayWalkScore: (jsonStr) ->
    json = (if (jsonStr) then eval("(" + jsonStr + ")") else "") #if no response, bypass the eval
    
    #if we got a score
    if json and json.status is 1
      htmlStr = "<a target=\"_blank\" href=\"" + json.ws_link + "\"><img src=\"" + json.logo_url + "\" /><span class=\"walkscore-scoretext\">" + json.walkscore + "</span></a>"
    
    #if no score was available
    else if json and json.status is 2
      htmlStr = "<a target=\"_blank\" href=\"" + json.ws_link + "\"><img src=\"" + json.logo_url + "\" /> <span class=\"walkscore-noscoretext\">Get Score</span></a>"
    
    #if didn't even get a json response
    else
      htmlStr = "<a target=\"_blank\" href=\"https://www.walkscore.com\"><img src=\"//cdn2.walk.sc/2/images/api-logo.png\" /> <span class=\"walkscore-noscoretext\">Get Score</span></a> "
    infoIconHtml = "<span id=\"ws_info\"><a href=\"http://www.walkscore.com/live-more\" target=\"_blank\"><img src=\"//cdn2.walk.sc/2/images/api-more-info.gif\" width=\"13\" height=\"13\"\" /></a></span>"
    
    #if you want to wrap extra tags around the html, can do that here before inserting into page element
    htmlStr = "<p>" + htmlStr + infoIconHtml + "</p>"
    
    #insert our new content into the container div:
    $("#walkscore-div").html htmlStr
    return

  timeserries: ->
    # get the DOM container if not exist make it
    try
      container = L.DomUtil.get(document.getElementsByClassName("container control-info")[0])
    catch e
      console.log "e"
      @makeDiv("control", "bottomleft")
      container = L.DomUtil.get(document.getElementsByClassName("container control-info")[0])

    console.log "container: ", container

    console.log d3.extent(d3.map(@text).forEach(get_time))
    
    x = d3.time.scale()
    y = d3.scale.linear()
    get_time = (d) ->
      d3.time.format.iso.parse d.date_time
    # for each in @text
    #   console.log get_time(each)
    map = @_m
    console.log "@_geoJson", @_geoJson

    L.pointsLayer(@_geoJson,
      # radius: get_radius
      applyStyle: @_circle_style
    ).addTo map 
    # chart = timeseries_chart(scheme).x(get_time).xLabel("Earthquake origin time").y(get_magnitude).yLabel("Magnitude").brushmove(on_brush)
    # d3.select("body").datum(@_geoJson.features).call chart

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
    # console.log "@_geoJson:", @_geoJson


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
    ], 15)
    @makeLayerController()
    # @_m.dragging.disable()
    # @makeHeatMap()
    @_m.boxZoom.enable()
    @_m.scrollWheelZoom.disable()
    # @makeHeatMap()
    # @makeD3onMap()
    drawControl = @showPathDirection(@_m)
    drawControl.addTo @_m
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
  # update texts
  return

draw = (data) ->
  # brush = d3.svg.brush().x(x).on("brush", _brushmove)

  paratext = L.paratext(data)
  textmap = paratext.makeMap()
  paratext.parseGeoJson()
  # heatmap = paratext.makeHeatMap(paratext.text)
  # d3onmap = paratext.makeD3onMap()
  control = paratext.makeDiv("control", "bottomleft")
  console.log "control", control
  timeserries = paratext.timeserries()
  texts = d3.selectAll("li")
  # ajaxSoda = paratext.addLayerFromSODA("https://data.cambridgema.gov/resource/vydm-qk5p.json").then
  # console.log "ajaxSoda", ajaxSoda
  addControlToDiv = paratext.addControlToDiv("control")
  
  # pathdirection = paratext.showPathDirection()
  # L.DomUtil.create

  # bding the L.D3 to jQuery and assiging data from and to datum
  $texts = $(texts[0])
  $texts.each ->
    $(this).data "datum", $(this).prop("__data__")
    return
  # jQuery handles the clicks
  timeout = undefined
timeout = 0
update = (data) ->
  paratext = L.paratext(data)
  console.log paratext
  for each in data
      setInterval (->
        # nodes.push id: ~~(Math.random() * foci.length)
        # force.start()
        ç

        # node = node.data(nodes)
        # node.enter().append("circle").attr("class", "node").attr("cx", (d) ->
        #   d.x
        # ).attr("cy", (d) ->
        #   d.y
        # ).attr("r", 8).style("fill", (d) ->
        #   fill d.id
        # ).style("stroke", (d) ->
        #   d3.rgb(fill(d.id)).darker 2
        # ).call force.drag
        return 
      ), 1500
      
    
# update()
# $('input').change update

