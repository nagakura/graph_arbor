#main.coffee
#

(()->
  Renderer = (canvas)->
    canvas = $(canvas).get(0)
    ctx = canvas.getContext("2d")
    particleSystem = null

    that =
      init:(system)->
        particleSystem = system
        particleSystem.screenSize(canvas.width, canvas.height)
        particleSystem.screenPadding(80)
        that.initMouseHandling()

      redraw:()->
        ctx.fillStyle = "white"
        ctx.fillRect(0,0, canvas.width, canvas.height)
        particleSystem.eachEdge((edge, pt1, pt2)->
          ctx.strokeStyle = "rgba(0,0,0, .333)"
          ctx.lineWidth = 1
          ctx.beginPath()
          ctx.moveTo(pt1.x, pt1.y)
          ctx.lineTo(pt2.x, pt2.y)
          ctx.stroke()
        )

        particleSystem.eachNode((node, pt)->
          w = 10
          ctx.fillStyle = if node.data.alone then "orange" else "black"
          ctx.fillRect(pt.x-w/2, pt.y-w/2, w,w)
        )

      initMouseHandling:()->
        dragged = null
        handler =
          clicked:(e)->
            pos = $(canvas).offset()
            _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
            dragged = particleSystem.nearest(_mouseP)

            if (dragged && dragged.node isnt null)
              dragged.node.fixed = true

            $(canvas).bind('mousemove', handler.dragged)
            $(window).bind('mouseup', handler.dropped)

            return false
          
          
          dragged:(e)->
            pos = $(canvas).offset()
            s = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)

            if (dragged and dragged.node isnt null)
              p = particleSystem.fromScreen(s)
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
            _mouseP = null
            return false
        
        # start listening
        $(canvas).mousedown(handler.clicked)
    return that
  
  
  $(document).ready(()->
    sys = arbor.ParticleSystem(1000, 600, 0.5) # create the system with sensible repulsion/stiffness/friction
    sys.parameters({gravity:true}) # use center-gravity to make the graph settle nicely (ymmv)
    sys.renderer = Renderer("#viewport") # our newly created renderer will have its .init() method called shortly by sys...

    ###
    sys.addEdge('a','b')
    sys.addEdge('b','c')
    sys.addEdge('c','d')
    sys.addEdge('d','e')
    sys.addEdge('e', 'a')
    ###
    
    sys.tweenNode('aa', 3, {color:"cyan", raduis:4})


    #sys.addNode('f', {alone:true, title: "shokai",  mass:.80})
    
    ###
    //sys.addEdge("f", "a")
    // or, equivalently:
    //
    // sys.graft({
    //   nodes:{
    //     f:{alone:true, mass:.25}
    //   }, 
    //   edges:{
    //     a:{ b:{},
    //         c:{},
    //         d:{},
    //         e:{}
    //     }
    //   }
    // })
    ###
  )

)(this.jQuery)
