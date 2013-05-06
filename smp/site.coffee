(($) ->

  Renderer = (elt)->
    dom = $(elt)
    canvas = dom.get(0)
    ctx = canvas.getContext("2d")
    gfx = arbor.Graphics(canvas)
    sys = null

    _vignette = null
    selected = null
    nearest = null
    _mouseP = null

    
    that =
      init:(pSystem)->
        sys = pSystem
        sys.screen(
          size:
            width:dom.width()
            height:dom.height()
          padding:[36,60,36,60])

        $(window).resize(that.resize)
        that.resize()
        that._initMouseHandling()
        
        if (document.referrer.match(/echolalia|atlas|halfviz/))
          that.switchSection('demos')
      
      resize:()->
        canvas.width = $(window).width()
        canvas.height = .75* $(window).height()
        sys.screen(
          size:
            width:canvas.width
            height:canvas.height)
        _vignette = null
        that.redraw()
      
      redraw:()->
        gfx.clear()
        sys.eachEdge((edge, p1, p2)->
          if (edge.source.data.alpha * edge.target.data.alpha is 0)
            return
          gfx.line(
            p1
            p2
            {stroke:"#b2b19d", width:2, alpha:edge.target.data.alpha})
        )
        
        sys.eachNode((node, pt)->
          #w = Math.max(60, 60+gfx.textWidth(node.name) )
          w = Math.max(node.data.important, node.data.important+gfx.textWidth(node.name) )
          if (node.data.alpha is 0)
            return
          #if (node.data.shape is 'dot')
            #gfx.oval(pt.x-w/2, pt.y-w/2, w, w, {fill:node.data.color, alpha:node.data.alpha})
          if (node.data.shape isnt 'dot')
            gfx.oval(pt.x-w/2, pt.y-w/2, w, w, {fill:"orange", alpha:1})
            gfx.text(node.data.title, pt.x, pt.y+7, {color:"black", align:"center", font:"Arial", size:12})
            gfx.text(node.data.title, pt.x, pt.y+7, {color:"black", align:"center", font:"Arial", size:12})
          ###
          else
            gfx.rect(pt.x-w/2, pt.y-8, w, 20, 4, {fill:node.data.color, alpha:node.data.alpha})
            gfx.text(node.name, pt.x, pt.y+9, {color:"white", align:"center", font:"Arial", size:12})
            gfx.text(node.name, pt.x, pt.y+9, {color:"white", align:"center", font:"Arial", size:12})
          ###
        )
        that._drawVignette()
      
      _drawVignette:()->
        w = canvas.width
        h = canvas.height
        r = 20

        if (not _vignette)
          top = ctx.createLinearGradient(0,0,0,r)
          top.addColorStop(0, "#e0e0e0")
          top.addColorStop(.7, "rgba(255,255,255,0)")

          bot = ctx.createLinearGradient(0,h-r,0,h)
          bot.addColorStop(0, "rgba(255,255,255,0)")
          bot.addColorStop(1, "white")

          _vignette = {top:top, bot:bot}
        
        ctx.fillStyle = _vignette.top
        ctx.fillRect(0,0, w,r)

        ctx.fillStyle = _vignette.bot
        ctx.fillRect(0,h-r, w,r)

      switchMode:(e)->
        if (e.mode=='hidden')
          dom.stop(true).fadeTo(e.dt,0, ()->
            sys.stop() if (sys)
            $(this).hide()
          )
        else if (e.mode is 'visible')
          dom.stop(true).css('opacity',0).show().fadeTo(e.dt,1,()->
            that.resize()
          )
          sys.start() if (sys)


      switchSection:(newSection)->
        parent = sys.getEdgesFrom(newSection)[0].source
        children = $.map(sys.getEdgesFrom(newSection), (edge)->
          return edge.target
        )
        
        sys.eachNode((node)->
          #user setting

          if (node.data.shape is 'dot') 
            return

          nowVisible = ($.inArray(node, children)>=0)
          newAlpha = if (nowVisible) then 1 else 0
          dt = if (nowVisible) then .5 else .5
          sys.tweenNode(node, dt, {alpha:newAlpha})

          if (newAlpha is 1)
            node.p.x = parent.p.x + .05*Math.random() - .025
            node.p.y = parent.p.y + .05*Math.random() - .025
            node.tempMass = .001
        )
      
      
      _initMouseHandling:()->
        selected = null
        nearest = null
        dragged = null
        oldmass = 1

        _section = null

        handler =
          moved:(e)->
            pos = $(canvas).offset()
            _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
            nearest = sys.nearest(_mouseP)

            if (not nearest.node)
              return false

            if (nearest.node.data.shape? not 'dot')
              selected = if (nearest.distance < 50) then nearest else null
              if (selected)
                 dom.addClass('linkable')
                 window.status = selected.node.data.link.replace(/^\//,"http://"+window.location.host+"/").replace(/^#/,'')
              else
                 dom.removeClass('linkable')
                 window.status = ''
            else if ($.inArray(nearest.node.name, ['arbor.js','code','docs','demos']) >=0 )
              if (nearest.node.name is _section)
                _section = nearest.node.name
                that.switchSection(_section)
              dom.removeClass('linkable')
              window.status = ''
            return false

          clicked:(e)->
            pos = $(canvas).offset()
            _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
            nearest = dragged = sys.nearest(_mouseP)
            
            if (nearest and selected and nearest.node is selected.node)
              link = selected.node.data.link
              if (link.match(/^#/))
                 $(that).trigger({type:"navigate", path:link.substr(1)})
              else
                 window.location = link
              return false
            
            if (dragged and dragged.node isnt null) 
              dragged.node.fixed = true

            $(canvas).unbind('mousemove', handler.moved)
            $(canvas).bind('mousemove', handler.dragged)
            $(window).bind('mouseup', handler.dropped)

            return false

          dragged:(e)->
            old_nearest = nearest and nearest.node._id
            pos = $(canvas).offset()
            s = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)

            if (not nearest)
              return
            if (dragged isnt null and dragged.node isnt null)
              p = sys.fromScreen(s)
              dragged.node.p = p

            return false

          dropped:(e)->
            if (dragged is null or dragged.node is undefined)
              return
            if (dragged.node isnt null)
              dragged.node.fixed = false
            dragged.node.tempMass = 1000
            dragged = null
            $(canvas).unbind('mousemove', handler.dragged)
            $(window).unbind('mouseup', handler.dropped)
            $(canvas).bind('mousemove', handler.moved)
            _mouseP = null
            return false

        $(canvas).mousedown(handler.clicked)
        $(canvas).mousemove(handler.moved)
    return that
  
  
  $(document).ready(()->


    testdata=
      a:
        title: "メンバー2013"
        important: 80
        relative:["b", "c", "d"]
      b:
        title: "geta6"
        important: 50
        relative:["a"]
      c:
        title: "山口尚人"
        important: 20
        relative:["a"]
      d:
        title: "shokai"
        important: 60
        relative:["a"]
    
    data =
      aa:{color:"red", shape:"dot", alpha:1}
    
      

    CLR =
      branch:"#b2b19d"
      code:"orange"
      doc:"#922E00"
      demo:"#a7af00"
    theUI =
      nodes:
        testdata
      edges:
        a:
          b:{length:1}
          c:{length:5}
          d:{length:3}
        b:
          a:{length:1}
        c:
          a:{length:5}
        d:
          a:{length:3}

    
    ###
    theUI =
      nodes:
        "arbor.js":{color:"red", shape:"dot", alpha:1}
        demos:{color:CLR.branch, shape:"dot", alpha:1}
        halfviz:{color:CLR.demo, alpha:0, link:'/halfviz'}
        atlas:{color:CLR.demo, alpha:0, link:'/atlas'
        echolalia:{color:CLR.demo, alpha:0, link:'/echolalia'}

        docs:{color:CLR.branch, shape:"dot", alpha:1}
        reference:{color:CLR.doc, alpha:0, link:'#reference'}
        introduction:{color:CLR.doc, alpha:0, link:'#introduction'}

        code:{color:CLR.branch, shape:"dot", alpha:1}
        github:{color:CLR.code, alpha:0, link:'https://github.com/samizdatco/arbor'}
        ".zip":{color:CLR.code, alpha:0, link:'/js/dist/arbor-v0.92.zip'}
        ".tar.gz":{color:CLR.code, alpha:0, link:'/js/dist/arbor-v0.92.tar.gz'}
      
      edges:
        "arbor.js":
          demos:{length:.8}
          docs:{length:.8}
          code:{length:.8}
        demos:
          halfviz:{}
          atlas:{}
          echolalia:{}
        docs:
          reference:{}
          introduction:{}
        code:
          ".zip":{}
          ".tar.gz":{}
          "github":{}
    ###
    sys = arbor.ParticleSystem()
    sys.parameters({stiffness:900, repulsion:2000, gravity:true, dt:0.015})
    sys.renderer = Renderer("#sitemap")
    sys.graft(theUI)
    
    ###
    nav = Nav("#nav")
    $(sys.renderer).bind('navigate', nav.navigate)
    $(nav).bind('mode', sys.renderer.switchMode)
    nav.init()
    ###
  )
)(this.jQuery)
