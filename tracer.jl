typealias Vec Vector{Float64}
typealias Point Vec
typealias Ink Vector{Float64}
typealias Distance Float64

normalize(v) = scale(v, 1/vecnorm(v))

type Line
  p::Point
  v::Vec
end

type Light
  center::Point
  color::Ink
  power::Distance
end

type Sphere
  center::Point
  radius::Distance
  color::Ink
  peculiarity::Float64
  reflection::Float64
end

type World
  background::Ink
  ambient::Ink
  lights::Array{Light}
  objects::Array{Sphere}
end

blend(c1, c2) = [c1[1]*c2[1], c1[2]*c2[2], c1[3]*c2[3]]

sqr(x) = x*x

function intersect( line, sphere )
  v = line.p - sphere.center
  p = dot(line.v, v)
  s = sqr(p) - dot(v,v) + sqr(sphere.radius)  
  if s < 0 
    d = +Inf
  elseif s == 0
    d = -p
  else
    sq = sqrt(s)
    if -p - sq > 0
      d = -p - sq
    else
      d = +Inf
    end
  end
  return d
end

function meet( x, y, sphere )
  r = true
  r = r && (x >= sphere.center[1] - sphere.radius) && (x <= sphere.center[1] + sphere.radius)
  r = r && (y >= sphere.center[2] - sphere.radius) && (y <= sphere.center[2] + sphere.radius)
  return r
end

function hit(world, line)  
  m = +Inf
  r = None
  ortho = line.v == [0, 0, 1]
  for s in world.objects
    if ortho && meet( line.p[1], line.p[2], s) || ! ortho
      d = intersect( line, s )
      if d < m
        m = d
        r = s
      end
    end
  end  
  return r, m
end

function trace(world, line)
  obj, d = hit(world, line)
  if obj != None
    p = line.p + line.v * d
    c = [ .0, .0 , .0]
    for light in world.lights    
        v = light.center - p
        h, _ = hit(world, Line(p, normalize(v))) 
        if h == None
          s = dot(normalize(p - obj.center), normalize(v))
          if(s > 0)
            c = c + blend( obj.color, s^obj.peculiarity * light.color * light.power * light.power / sqr(vecnorm(v)) )
          end
        end
    end
    reflection = trace(world, Line(p, normalize(p - obj.center)))
    if reflection != None
      c = c + obj.reflection * blend(reflection, normalize(obj.color))
    end
    return c +  blend(world.ambient, normalize(obj.color))
  else
    return None
  end
end

