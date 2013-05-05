// Generated by CoffeeScript 1.6.2
(function() {
  (function($) {
    var Renderer;

    Renderer = function(elt) {
      var canvas, ctx, dom, gfx, nearest, selected, sys, that, _mouseP, _vignette;

      dom = $(elt);
      canvas = dom.get(0);
      ctx = canvas.getContext("2d");
      gfx = arbor.Graphics(canvas);
      sys = null;
      _vignette = null;
      selected = null;
      nearest = null;
      _mouseP = null;
      that = {
        init: function(pSystem) {
          sys = pSystem;
          sys.screen({
            size: {
              width: dom.width(),
              height: dom.height()
            },
            padding: [36, 60, 36, 60]
          });
          $(window).resize(that.resize);
          that.resize();
          that._initMouseHandling();
          if (document.referrer.match(/echolalia|atlas|halfviz/)) {
            return that.switchSection('demos');
          }
        },
        resize: function() {
          canvas.width = $(window).width();
          canvas.height = .75 * $(window).height();
          sys.screen({
            size: {
              width: canvas.width,
              height: canvas.height
            }
          });
          _vignette = null;
          return that.redraw();
        },
        redraw: function() {
          gfx.clear();
          sys.eachEdge(function(edge, p1, p2) {
            if (edge.source.data.alpha * edge.target.data.alpha === 0) {
              return;
            }
            return gfx.line(p1, p2, {
              stroke: "#b2b19d",
              width: 2,
              alpha: edge.target.data.alpha
            });
          });
          sys.eachNode(function(node, pt) {
            var w;

            w = Math.max(20, 20 + gfx.textWidth(node.name));
            if (node.data.alpha === 0) {
              return;
            }
            if (node.data.shape === 'dot') {
              gfx.oval(pt.x - w / 2, pt.y - w / 2, w, w, {
                fill: node.data.color,
                alpha: node.data.alpha
              });
              gfx.text(node.name, pt.x, pt.y + 7, {
                color: "white",
                align: "center",
                font: "Arial",
                size: 12
              });
              return gfx.text(node.name, pt.x, pt.y + 7, {
                color: "white",
                align: "center",
                font: "Arial",
                size: 12
              });
            } else {
              gfx.rect(pt.x - w / 2, pt.y - 8, w, 20, 4, {
                fill: node.data.color,
                alpha: node.data.alpha
              });
              gfx.text(node.name, pt.x, pt.y + 9, {
                color: "white",
                align: "center",
                font: "Arial",
                size: 12
              });
              return gfx.text(node.name, pt.x, pt.y + 9, {
                color: "white",
                align: "center",
                font: "Arial",
                size: 12
              });
            }
          });
          return that._drawVignette();
        },
        _drawVignette: function() {
          var bot, h, r, top, w;

          w = canvas.width;
          h = canvas.height;
          r = 20;
          if (!_vignette) {
            top = ctx.createLinearGradient(0, 0, 0, r);
            top.addColorStop(0, "#e0e0e0");
            top.addColorStop(.7, "rgba(255,255,255,0)");
            bot = ctx.createLinearGradient(0, h - r, 0, h);
            bot.addColorStop(0, "rgba(255,255,255,0)");
            bot.addColorStop(1, "white");
            _vignette = {
              top: top,
              bot: bot
            };
          }
          ctx.fillStyle = _vignette.top;
          ctx.fillRect(0, 0, w, r);
          ctx.fillStyle = _vignette.bot;
          return ctx.fillRect(0, h - r, w, r);
        },
        switchMode: function(e) {
          if (e.mode === 'hidden') {
            return dom.stop(true).fadeTo(e.dt, 0, function() {
              if (sys) {
                sys.stop();
              }
              return $(this).hide();
            });
          } else if (e.mode === 'visible') {
            dom.stop(true).css('opacity', 0).show().fadeTo(e.dt, 1, function() {
              return that.resize();
            });
            if (sys) {
              return sys.start();
            }
          }
        },
        switchSection: function(newSection) {
          var children, parent;

          parent = sys.getEdgesFrom(newSection)[0].source;
          children = $.map(sys.getEdgesFrom(newSection), function(edge) {
            return edge.target;
          });
          return sys.eachNode(function(node) {
            var dt, newAlpha, nowVisible;

            if (node.data.shape === 'dot') {
              return;
            }
            nowVisible = $.inArray(node, children) >= 0;
            newAlpha = nowVisible ? 1 : 0;
            dt = nowVisible ? .5 : .5;
            sys.tweenNode(node, dt, {
              alpha: newAlpha
            });
            if (newAlpha === 1) {
              node.p.x = parent.p.x + .05 * Math.random() - .025;
              node.p.y = parent.p.y + .05 * Math.random() - .025;
              return node.tempMass = .001;
            }
          });
        },
        _initMouseHandling: function() {
          var dragged, handler, oldmass, _section;

          selected = null;
          nearest = null;
          dragged = null;
          oldmass = 1;
          _section = null;
          handler = {
            moved: function(e) {
              var pos;

              pos = $(canvas).offset();
              _mouseP = arbor.Point(e.pageX - pos.left, e.pageY - pos.top);
              nearest = sys.nearest(_mouseP);
              if (!nearest.node) {
                return false;
              }
              if (nearest.node.data.shape(!'dot')) {
                selected = nearest.distance < 50 ? nearest : null;
                if (selected) {
                  dom.addClass('linkable');
                  window.status = selected.node.data.link.replace(/^\//, "http://" + window.location.host + "/").replace(/^#/, '');
                } else {
                  dom.removeClass('linkable');
                  window.status = '';
                }
              } else if ($.inArray(nearest.node.name, ['arbor.js', 'code', 'docs', 'demos']) >= 0) {
                if (nearest.node.name === _section) {
                  _section = nearest.node.name;
                  that.switchSection(_section);
                }
                dom.removeClass('linkable');
                window.status = '';
              }
              return false;
            },
            clicked: function(e) {
              var link, pos;

              pos = $(canvas).offset();
              _mouseP = arbor.Point(e.pageX - pos.left, e.pageY - pos.top);
              nearest = dragged = sys.nearest(_mouseP);
              if (nearest && selected && nearest.node === selected.node) {
                link = selected.node.data.link;
                if (link.match(/^#/)) {
                  $(that).trigger({
                    type: "navigate",
                    path: link.substr(1)
                  });
                } else {
                  window.location = link;
                }
                return false;
              }
              if (dragged && dragged.node !== null) {
                dragged.node.fixed = true;
              }
              $(canvas).unbind('mousemove', handler.moved);
              $(canvas).bind('mousemove', handler.dragged);
              $(window).bind('mouseup', handler.dropped);
              return false;
            },
            dragged: function(e) {
              var old_nearest, p, pos, s;

              old_nearest = nearest && nearest.node._id;
              pos = $(canvas).offset();
              s = arbor.Point(e.pageX - pos.left, e.pageY - pos.top);
              if (!nearest) {
                return;
              }
              if (dragged !== null && dragged.node !== null) {
                p = sys.fromScreen(s);
                dragged.node.p = p;
              }
              return false;
            },
            dropped: function(e) {
              if (dragged === null || dragged.node === void 0) {
                return;
              }
              if (dragged.node !== null) {
                dragged.node.fixed = false;
              }
              dragged.node.tempMass = 1000;
              dragged = null;
              $(canvas).unbind('mousemove', handler.dragged);
              $(window).unbind('mouseup', handler.dropped);
              $(canvas).bind('mousemove', handler.moved);
              _mouseP = null;
              return false;
            }
          };
          $(canvas).mousedown(handler.clicked);
          return $(canvas).mousemove(handler.moved);
        }
      };
      return that;
    };
    return $(document).ready(function() {
      var CLR, sys, theUI;

      CLR = {
        branch: "#b2b19d",
        code: "orange",
        doc: "#922E00",
        demo: "#a7af00"
      };
      theUI = {
        nodes: {
          "aa": {
            color: "red",
            shape: "dot",
            alpha: 0.6
          },
          "bb": {
            color: "orange",
            shape: "dot",
            alpha: 1
          }
        },
        edges: {
          "aa": {
            "bb": {
              lenght: 6
            }
          }
        }
      };
      /*
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
      */

      sys = arbor.ParticleSystem();
      sys.parameters({
        stiffness: 900,
        repulsion: 2000,
        gravity: true,
        dt: 0.015
      });
      sys.renderer = Renderer("#sitemap");
      return sys.graft(theUI);
      /*
      nav = Nav("#nav")
      $(sys.renderer).bind('navigate', nav.navigate)
      $(nav).bind('mode', sys.renderer.switchMode)
      nav.init()
      */

    });
  })(this.jQuery);

}).call(this);