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
    

  formatTime: (arg)->
    if arg == "month"
      return monthNameFormat = d3.time.format("%B")
    else if arg == "day"
      return dayNameFormat = d3.time.format("%Y-%m-%d")
    else if arg == "hour"
      return HourNameFormat = d3.time.format("%H")

  makeHeatMap: (d, max_zoom, time_interval)->
    @_m.removeLayer @_heat if @_heat

    @formatTime(time_interval)

    console.log d
    draw = true
    coordinates = []
    if d == @text
      for key, value of @text
        try
          coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) 
        catch e
          coordinates.push new L.LatLng(value.address.latitude, value.address.longitude) 
    else
      for key, value of @text
        try
          coordinates.push new L.LatLng(value.coordinates.latitude, value.coordinates.longitude) if @formatTime(time_interval)(new Date(d3.time.format.iso.parse value.date_time)) == @formatTime(time_interval)(d.x)
        catch e
          coordinates.push new L.LatLng(value.address.latitude, value.address.longitude) if @formatTime(time_interval)(new Date(d3.time.format.iso.parse value.date_time)) == @formatTime(time_interval)(d.x)
        
    @_heat = L.heatLayer(coordinates,
      maxZoom: max_zoom
    )
    @_heat.addTo(@_m)
    # @_heat.addLatLng coordinates 
    timeout = undefined
    @_viewSet = @_m.getCenter() if @_viewSet is undefined
    @_zoomSet = @_m.getZoom() if @_viewZoom is undefined
    @_m.on "load", ->
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
        L.DomUtil.enableTextSelection(_domEl)  
        @_m.getContainer().getElementsByClassName("leaflet-control-container")[0].appendChild(_domEl)
        _domObj = $(L.DomUtil.get(_domEl))
        _domObj.css('width', $(@_m.getContainer())[0].clientWidth)
        _domObj.css('height', $(@_m.getContainer())[0].clientHeight/4)
        _domObj.css('background-color', 'black')
        L.DomUtil.setOpacity(L.DomUtil.get(_domEl), 1)
        L.DomUtil.setPosition(L.DomUtil.get(_domEl), L.point(0, $(@_m.getContainer())[0].clientHeight/2 + $(@_m.getContainer())[0].clientHeight/4), disable3D=0)
        # filter_el = L.DomUtil.create('select', 'filter', _domEl)
        # $(L.DomUtil.get(filter_el)).css('position', 'absolute').css('right', '50px').append('<option>by hour</option><option>by day</option>')
        # L.DomEvent.addListener L.DomUtil.get(filter_el), 'click', (e) =>
        #     e.preventDefault()
        #     e.stopPropagation()
        # console.log filter_el
    )
    legend = L.control(position: "bottomright")
    legend.onAdd = (map) =>
      div = L.DomUtil.create("div", "info legend")
      div.innerHTML = "<form class='target'><select class='target'><option>by month</option><option>by day</option><option>hour</option></select></form>"
      L.DomEvent.on div.firstChild.firstElementChild, "change", (e) ->
        console.log @, _this
        unless @value is "none"
          console.log @value
          _this._chart.unload()
          counts = _this.groupBy("date_time", @value.replace('by ', ''))
          all_dates = []
          values = []
          d3.map(counts).forEach (index, value) => 
            console.log d3.time.format("%Y-%m-%d").parse(value.key)
            values.push(value.values)
            all_dates.push(value.key)
          
          months = []
            
          all_dates.shift()
          values.shift()
          all_dates.shift()
          values.shift()
          all_dates.unshift "x"
          values.unshift "Accident Frequency"
          # if timearg == "month"
          #   timeformater = "%B"
          # else if timearg == "day"
          #   timeformater = "%a"
          # else if timearg == "hour"
          #   timeformater = "%H"
          _this._chart.load(columns: [
            values
            all_dates
          ])

        else
          console.log "kldkd!!"

        return

      div.firstChild.onmousedown = div.firstChild.ondblclick = L.DomEvent.stopPropagation
      div
    new divControl()
    legend.addTo @_m
    
      
  
  makeLayerController: ->
    L.control.layers(
      "Base Map": L.mapbox.tileLayer("arminavn.ib1f592g").addTo(@_m)
      "Open Street": L.mapbox.tileLayer("arminavn.jl495p2g")
    ,
    ).addTo @_m

  groupBy: (by_field, timearg)->
    monthNameFormat = d3.time.format("%B")
    dayNameFortmat = d3.time.format("%a")
    if by_field = "date_time"
      features = @_geoJson.features.map( (d) ->
        return new Date(d3.time.format.iso.parse(d.properties.date_time))
        )
      nest = d3.nest().key((d) =>
        @formatTime(timearg)(d)
        # dayNameFortmat(d)
      # ).key((d) ->
      #   d.properties.day_of_week
      ).sortKeys((d) ->
        return
      ).rollup((d) ->
        d.length
      ).entries(features)
    else
      features = @_geoJson.features.map( (d) ->
        return d
        )
      nest = d3.nest().key((d) ->
        "d.properties.#{by_field}"
      # ).key((d) ->
      #   d.properties.day_of_week
      ).rollup((d) ->
        d.length
      ).entries(features)

    return nest

  timeserries: (timearg)->
    counts = @groupBy("date_time", timearg)
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
    if timearg == "month"
      timeformater = "%B"
    else if timearg == "day"
      timeformater = "%Y-%m-%d"
    else if timearg == "hour"
      timeformater = "%H"

    try
        container = L.DomUtil.get(document.getElementsByClassName("container control-info")[0])
    catch e
      @makeDiv("control", "bottomleft")
      container = L.DomUtil.get(document.getElementsByClassName("container control-info")[0])
    L.DomUtil.enableTextSelection(container) 
    L.DomEvent.on container, "mouseover", (e) =>
      @_m.dragging.disable()
      return
    L.DomEvent.on container, "mouseout", (e) =>
      @_m.dragging.enable()
      return
        
    margin =
      top: 5
      right: 5
      bottom: 40
      left: 45
    width = 960 - margin.left - margin.right
    height = 80
    d3.select(container).append("div").attr("id", "chart")
    console.log values, all_dates
    console.log "chart", @_chart
    if @_chart isnt undefined
      @_chart.unload("x", "Accident Frequency")
      @_chart.load columns: [
        values
        all_dates
      ]
      return
    else
      @_chart = c3.generate(
        data:
          onmouseover: (d, element) => @makeHeatMap(d, 17, timearg)
          x: "x"
          xFormat: timeformater
          columns: [
            all_dates
            values
            
          ]

        axis:
          x:
            type: "timeseries"
            tick:
              format: d3.time.format(timeformater)
        size:
          height: $(@_m.getContainer())[0].clientHeight/4
          width: $(@_m.getContainer())[0].clientWidth - 100

        legend:
          item:
            onmouseover: => @makeHeatMap(@text, 19, timearg)
            onmouseout: => 
              @makeHeatMap([])
              tooltip:
                content: "Show All"
                show: true
      )
      @_chart.unload()
      setTimeout (=>
        @_chart.load columns: [
          values
        ]
        return
      ), 1000
      
      
      return chart
    all_dates = []
    values = []
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
    ], 14)
    @makeLayerController()
    @_m.boxZoom.enable()
    @_m.scrollWheelZoom.disable()
  

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


queue().defer(d3.json, "https://data.cambridgema.gov/resource/ybny-g9cv.json?$limit=50000").await (err, texts) ->
  draw texts
  return
# catch e
#   queue().defer(d3.json, "https://data.cambridgema.gov/resource/ybny-g9cv.json").await (err, texts) ->
#     draw texts
#     return




draw = (data) ->
  serries = ["hour", "day", "month"]
  paratext = L.paratext(data)
  textmap = paratext.makeMap()
  paratext.parseGeoJson()
  control = paratext.makeDiv("control", "bottomleft") 
  timeout = undefined 
  # d3.
  paratext.timeserries("month")

  # for each in serries
  #   # setTimeout (->
  #   #   timeserries = paratext.timeserries(each)
  #   #   return
  #   # ), 1000
  #   timeout = setTimeout(->
  #     # if timeout isnt 0 
  #     timeserries = paratext.timeserries(each)
  #       # timeout = 0
  #     # return
  #   , 1000)
  #   # timeout = 0
  #   # return 
  #   # timeout = 0
  # return
  
# timeout = 0
$(document).ready ->
  


  


