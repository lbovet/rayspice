using Base.Graphics
using Cairo
using Tk
@everywhere include("tracer.jl")

darkgray = [ .08, .08, .08 ]
grey = [ .4, .4, .4 ]
red = [.6, .1, .3]
blue = [ .1, .3, .6]
green = [ .1, .6, .3]
yellow = [ .6, .6, .2]
gold = [ .3, .2, .05 ]
white = [ 1, 1, 1 ]
black = [ 0., 0., 0. ]

function world()
  return World( black, darkgray,
    [ Light( [ 1, 0, -0.2 ], white, .6 ), 
      Light( [ -10, -5, 1 ], yellow, 10 ),
      Light( [ 0, -5, -10 ], white, 10 ) ],
    [ Sphere( [ .3, .5, .6 ], .2, gold, 50, .7 ),
     Sphere( [ .6, .4, .25 ], .14, red, 4, 0.05 ),
     Sphere( [ .38, .8, .2 ], .10, blue, 4, 0.05 ),
     Sphere( [ .7, .7, .3 ], .16, white, 20, 1 ),
     Sphere( [ .2, .2, .5 ], .08, green, 6, .5 ),
     Sphere( [ .8, .2, 2 ], .18, blue, 50, 1 ),
     Sphere( [ .7, .25, .1 ], .05, gold, 1, 0 ) ] )
end

@everywhere function tile(world, x1::Int, x2::Int, y1::Int, y2::Int, w::Int, h::Int)
  buf = Array(Uint32, convert(Int, x2-x1), convert(Int, y2-y1))
  fill!(buf, 0)
  for i = x1:x2-1
    for j = y1:y2-1
      p = trace( world, Line([i/w, j/h, 0], [0, 0, 1 ]) )
      if p != None
        r = i-x1+1
        c = j-y1+1
        buf[c,r] = convert(Uint32, max(0, round(255*min(1.0, p[3]))))
        buf[c,r] |= convert(Uint32, max(0, round(255*min(1.0, p[2])))) << 8
        buf[c,r] |= convert(Uint32, max(0, round(255*min(1.0, p[1])))) << 16
      end
    end    
  end
  return buf
end

function paint_buf(c, ctx, ref, x1, y1, dx, dy)
    buf = fetch(ref)
    s = CairoRGBSurface(buf)
    image(ctx, s, x1, y1, dx, dy)
    reveal(c)
    Tk.update()
end

function raytrace(world_func)
  w = 800
  h = 800
  win = Toplevel("RaySpice", w, h)
  c = Canvas(win)
  pack(c, expand=true, fill="both")
  ctx = getgc(c)
  set_source_rgb(ctx, 0, 0, 0)
  paint(ctx)
  Tk.update()
  world = world_func()
  t = time()
  n = 4
  dx = div(w, n)
  dy = div(h, n)
  refs = Array(RemoteRef, n, n)
  for i = 0:n-1
    x1 = i*dx    
    for j = 0:n-1
      y1 = j*dy 
      buf_ref = @spawn tile(world, x1, x1 + dx, y1 ,y1 + dy, w, h)
      refs[i+1,j+1] = buf_ref
    end
  end
  for i = 0:n-1  
    x1 = i*dx
    for j = 0:n-1
      y1 = j*dy      
      @async paint_buf(c, ctx, refs[i+1,j+1], x1, y1, dx, dy)
    end
  end
  println(time()-t)
end

raytrace(world)
