export Circle
export Square
export Rectangle
export AbstractDisk
export AbstractQuadrilateral
export AbstractRectangle
export AbstractUniformDisk

using Formatting
using LinearAlgebra
using NLopt
using RecipesBase
using StaticArrays

abstract type AbstractDisk <: AbstractShape{2,1} end
abstract type AbstractUniformDisk <: AbstractDisk end
abstract type AbstractQuadrilateral <: AbstractShape{2,4} end
abstract type AbstractRectangle <: AbstractQuadrilateral end

################################################################################
# CIRCLE
"""
    Circle <: AbstractDisk

Fields: `radius`, `origin`, `ϕ`, `sinϕ`, `cosϕ`, `corners`, `models`
"""
struct Circle <: AbstractUniformDisk
    radius::Float64
    origin::Point{2,Cartesian}
    ϕ::Float64
    sinϕ::Float64
    cosϕ::Float64
    corners::Tuple{}
    models::Array{Opt,1}

    function Circle(radius::Real, origin::Point{2}, ϕ::Real)
        snϕ, csϕ = sincos(ϕ)
        c = new(radius,origin,ϕ,snϕ,csϕ)
        models = build_models(c)
        return new(radius,origin,ϕ,snϕ,csϕ,(),models)
    end
end

"""
    Circle(radius, origin::Point{2}; ϕ=0, reference=:center) -> circle
"""
function Circle(radius::Real, origin::Point{2}; ϕ::Real=0, reference::Symbol=:center)
    if Base.sym_in(reference, (:bottom, :Bottom, :b, :B))
        origin = origin + rotate( Point( 0, radius), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:top, :Top, :T, :t))
        origin = origin + rotate( Point( 0,-radius), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:left, :Left, :L, :l))
        origin = origin + rotate( Point( radius, 0), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:right, :Right, :R, :r))
        origin = origin + rotate( Point(-radius, 0), cos(ϕ), sin(ϕ))
    end
    return Circle(radius,origin,ϕ)
end

"""
    Circle(radius, x0, y0; ϕ=0, reference=:center) -> circle
"""
Circle(radius::Real, x0::Real, y0::Real; kwargs...) = Circle(radius, Point(x0,y0); kwargs...)

"""
    (::Circle)(p::Point{2}) --> is_in_circle::Bool
"""
(c::Circle)(p::Point{2}) = norm(p-c.origin) < c.radius-eps(c.radius)


"""
    perimeter(t,shape,side) -> x,y,dx/dt,dy/dt
"""
function perimeter(t::Number,c::Circle,side::Int)
    sn,cs = sincos(t)
    x = c.origin.x + c.radius*cs
    y = c.origin.y + c.radius*sn
    ẋ = -c.radius*sn
    ẏ =  c.radius*cs
    return x,y,ẋ,ẏ
end

function Base.getproperty(c::Circle, sym::Symbol)
    if Base.sym_in(sym,(:R,:r,:rad))
        return getfield(c,:radius)
    else
        return getfield(c,sym)
    end
end

function Base.propertynames(::Circle,private=false)
    if private
        return fieldnames(Circle)
    else
        return (:radius, :origin)
    end
end


import ..PRINTED_COLOR_NUMBER
import ..PRINTED_COLOR_DARK

function Base.show(io::IO, circle::Circle)
    printstyled(io, "Circle", color=PRINTED_COLOR_DARK)
    print(io, "(radius: ")
    printstyled(io, fmt("2.2f",circle.radius), color=PRINTED_COLOR_NUMBER)
    print(io, ", center: ", circle.origin, ")")
end

################################################################################
# SQUARE
"""
    Square <: AbstractQuadrilateral <: AbstractShape{2,4}

Fields: `a`, `origin`, `ϕ`, `sinϕ`, `cosϕ`, `corners`, `models`
"""
struct Square <: AbstractRectangle
    a::Float64
    origin::Point{2,Cartesian}
    ϕ::Float64
    sinϕ::Float64
    cosϕ::Float64
    corners::NTuple{4,Point{2,Cartesian}}
    models::Array{Opt,1}

    function Square(a::Real, origin::Point{2}, ϕ::Number)
        s = new(a,origin,ϕ,sin(ϕ),cos(ϕ))
        models = build_models(s)
        c1 = rotate(s.origin+Point( s.a/2, s.a/2), s)
        c2 = rotate(s.origin+Point(-s.a/2, s.a/2), s)
        c3 = rotate(s.origin+Point(-s.a/2,-s.a/2), s)
        c4 = rotate(s.origin+Point( s.a/2,-s.a/2), s)
        return new(a,origin,ϕ,sin(ϕ),cos(ϕ),(c1,c2,c3,c4),models)
    end
end

"""
    Square(a, origin::Point; ϕ=0, reference=:center) -> square

`a` length of sides
"""
function Square(a::Real, origin::Point{2}; ϕ::Real=0, reference::Symbol=:center)
    if Base.sym_in(reference,(:bottom, :Bottom, :b, :B))
        origin += rotate(Point( 0, a/2),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:top, :Top, :T, :t))
        origin += rotate(Point( 0,-a/2),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:left, :Left, :L, :l))
        origin += rotate(Point( a/2, 0),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:right, :Right, :R, :r))
        origin += rotate(Point(-a/2, 0),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:topright, :TopRight, :TR, :tr, :ne, :NE))
        origin += rotate(Point(-a/2,-a/2),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:topleft, :TopLeft, :TL, :tl, :nw, :NW))
        origin += rotate(Point( a/2,-a/2),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:bottomleft, :BottomLeft, :BL, :bl, :sw, :SW))
        origin += rotate(Point( a/2, a/2),cos(ϕ),sin(ϕ))
    elseif Base.sym_in(reference,(:bottomright, :BottomRight, :BR, :br, :se, :SE))
        origin += rotate(Point(-a/2, a/2),cos(ϕ),sin(ϕ))
    end
    return Square(a,origin,ϕ)
end

"""
    Square(a,x0,y0; ϕ=0, reference=:center)
"""
Square(a::Real, x0::Real, y0::Real; kwargs...) = Square(a,Point(x0,y0); kwargs...)

"""
    (::Square)(p::Point) -> is_in_square::Bool
"""
function (s::Square)(p::Point{2})
    purot = unrotate(p, s)
    p = purot - s.origin
    return -s.a/2+eps(s.a/2) < p.x < s.a/2-eps(s.a/2)  &&  -s.a/2+eps(s.a/2) < p.y < s.a/2-eps(s.a/2)
end

function perimeter(t::Number,s::Square,side::Int)
    if side==1
        x = -s.a/2
        y = -s.a/2 + t*s.a
        ẋ = 0
        ẏ = s.a
    elseif side==2
        x =  s.a/2
        y = -s.a/2 + t*s.a
        ẋ = 0
        ẏ = s.a
    elseif side==3
        x = -s.a/2 + t*s.a
        y = -s.a/2
        ẋ = s.a
        ẏ = 0
    elseif side==4
        x = -s.a/2 + t*s.a
        y =  s.a/2
        ẋ = s.a
        ẏ = 0
    end
    x += s.origin.x
    y += s.origin.y
    p = rotate(Point(x,y),s)
    ṗ = rotate(Point(ẋ,ẏ),s.cosϕ,s.sinϕ)
    return p.x, p.y, ṗ.x, ṗ.y
end

function Base.getproperty(s::Square, sym::Symbol)
    if Base.sym_in(sym,(:A,:B,:b))
        return getfield(s,:a)
    else
        return getfield(s,sym)
    end
end

function Base.propertynames(::Square,private=false)
    if private
        return fieldnames(Square)
    else
        return (:a, :origin, :ϕ)
    end
end


import ..PRINTED_COLOR_NUMBER
import ..PRINTED_COLOR_DARK

function Base.show(io::IO, square::Square)
    printstyled(io, "Square", color=PRINTED_COLOR_DARK)
    print(io, "(a: ")
    printstyled(io, fmt("2.2f",square.a), color=PRINTED_COLOR_NUMBER)
    print(io, ", ϕ: ")
    printstyled(io, fmt("3.1f",180square.ϕ/π),"°", color=PRINTED_COLOR_NUMBER)
    print(io, ", center: ", square.origin, ")")
end


################################################################################
# RECTANGLE
"""
    Rectangle <: AbstractQuadrilateral <: AbstractShape{2,4}

Fields: `a`, `b`, `origin`, `ϕ`, `sinϕ`, `cosϕ`, `corners`, `models`
"""
struct Rectangle <: AbstractRectangle
    a::Float64
    b::Float64
    origin::Point{2,Cartesian}
    ϕ::Float64
    sinϕ::Float64
    cosϕ::Float64
    corners::NTuple{4,Point{2,Cartesian}}
    models::Array{Opt,1}

    function Rectangle(a::Real, b::Real, origin::Point{2}, ϕ::Real)
        r = new(a,b,origin,ϕ,sin(ϕ),cos(ϕ))
        models = build_models(r)
        c1 = rotate(r.origin+Point( r.a/2, r.b/2), r)
        c2 = rotate(r.origin+Point(-r.a/2, r.b/2), r)
        c3 = rotate(r.origin+Point(-r.a/2,-r.b/2), r)
        c4 = rotate(r.origin+Point( r.a/2,-r.b/2), r)
        return new(a,b,origin,ϕ,sin(ϕ),cos(ϕ),(c1,c2,c3,c4),models)
    end
end

"""
    Rectangle(a, b, origin::Point; ϕ=0, reference=:center) -> r

`a`, `b` length of sides, `ϕ` is angle of rotation relative to `reference`
"""
function Rectangle(a::Real, b::Real, origin::Point{2}; ϕ::Real=0, reference::Symbol=:center)
    if Base.sym_in(reference,(:bottom, :Bottom, :b, :B))
        origin += rotate(Point( 0, b/2), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:top, :Top, :T, :t))
        origin += rotate(Point( 0,-b/2), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:left, :Left, :L, :l))
        origin += rotate(Point( a/2, 0), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:right, :Right, :R, :r))
        origin += rotate(Point(-a/2, 0), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:topright, :TopRight, :TR, :tr, :ne, :NE))
        origin += rotate(Point(-a/2,-b/2), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:topleft, :TopLeft, :TL, :tl, :nw, :NW))
        origin += rotate(Point( a/2,-b/2), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:bottomleft, :BottomLeft, :BL, :bl, :sw, :SW))
        origin += rotate(Point( a/2, b/2), cos(ϕ), sin(ϕ))
    elseif Base.sym_in(reference,(:bottomright, :BottomRight, :BR, :br, :se, :SE))
        origin += rotate(Point(-a/2, b/2), cos(ϕ), sin(ϕ))
    end
    return Rectangle(a,b,origin,ϕ)
end

"""
    Rectangle(a, b, x0, y0; ϕ=0, reference=:center)
"""
Rectangle(a::Real, b::Real, x0::Real, y0::Real; kwargs...) = Rectangle(a,b,Point(x0,y0); kwargs...)

"""
    Rectangle(s::Square) -> r
"""
Rectangle(s::Square) = Rectangle(s.a,s.a,s.origin; ϕ = s.ϕ)

"""
    (::Rectangle)(p::Point) -> is_in_rectangle::Bool
"""
function (r::Rectangle)(p::Point{2})
    purot = unrotate(p, r)
    p = purot - r.origin
    return -r.a/2+eps(r.a/2) < p.x < r.a/2-eps(r.a/2)  &&  -r.b/2+eps(r.b/2) < p.y < r.b/2-eps(r.b/2)
end

function perimeter(t::Number,r::Rectangle,side::Int)
    if side==1
        x = -r.a/2
        y = -r.b/2 + t*r.b
        ẋ = 0
        ẏ = r.b
    elseif side==2
        x =  r.a/2
        y = -r.b/2 + t*r.b
        ẋ = 0
        ẏ = r.b
    elseif side==3
        x = -r.a/2 + t*r.a
        y = -r.b/2
        ẋ = r.a
        ẏ = 0
    elseif side==4
        x = -r.a/2 + t*r.a
        y =  r.b/2
        ẋ = r.a
        ẏ = 0
    end
    x += r.origin.x
    y += r.origin.y
    p = rotate(Point(x,y),r)
    ṗ = rotate(Point(ẋ,ẏ),r.cosϕ,r.sinϕ)
    return p.x, p.y, ṗ.x, ṗ.y
end

function Base.getproperty(r::Rectangle, sym::Symbol)
    if Base.sym_in(sym,(:A,))
        return getfield(r,:a)
    elseif Base.sym_in(sym,(:B,))
        return getfield(r,:b)
    else
        return getfield(r,sym)
    end
end

function Base.propertynames(::Rectangle,private=false)
    if private
        return fieldnames(Rectangle)
    else
        return (:a, :b, :origin, :ϕ)
    end
end


import ..PRINTED_COLOR_NUMBER
import ..PRINTED_COLOR_DARK

function Base.show(io::IO, rect::Rectangle)
    printstyled(io, "Rectangle", color=PRINTED_COLOR_DARK)
    print(io, "(a: ")
    printstyled(io, fmt("2.2f", rect.a), color=PRINTED_COLOR_NUMBER)
    print(io, ", b: ")
    printstyled(io, fmt("2.2f", rect.b), color=PRINTED_COLOR_NUMBER)
    print(io, ", ϕ: ")
    printstyled(io, fmt("3.1f", 180rect.ϕ/π),"°", color=PRINTED_COLOR_NUMBER)
    print(io, ", center: ", rect.origin, ")")
end

################################################################################
# AUXILLIARIES

import ..NL_NORMAL_ALGORITHM
import ..NL_NORMAL_XTOL
import ..NL_NORMAL_FTOL
import ..NL_NORMAL_MAXEVAL

"""
    rotate(x,y,cosϕ,sinϕ) -> xrot, yrot

rotate by `ϕ` about origin

----------------
    rotate(x,y,shape) -> xrot, yrot

rotate about `shape`'s center by `shape`'s angle
"""
rotate(p::Point{2},cosϕ::Real,sinϕ::Real) = iszero(sinϕ) ? p : Point(cosϕ*p.x-sinϕ*p.y, sinϕ*p.x+cosϕ*p.y)
rotate(p::Point{2},s::AbstractShape{2}) = s.origin + rotate(p-s.origin,s.cosϕ,s.sinϕ)

function rotate(p::AbstractArray,cosϕ::Real,sinϕ::Real)
    prot = Array{Point{2}}(undef,size(p))
    rotate!(prot,p,cosϕ,sinϕ)
    return prot
end
function rotate(p::AbstractArray,s::AbstractShape{2})
    prot = Array{Point{2}}(undef,size(p))
    rotate!(prot,p.-s.origin,s.cosϕ,s.sinϕ)
    return prot .+ s.origin
end

function rotate!(prot::AbstractArray,p::Point{2},cosϕ::Real,sinϕ::Real)
    for i ∈ eachindex(p) prot[i] = rotate(p[i],cosϕ,sinϕ) end
    return nothing
end


"""
    unrotate(x,y,cosϕ,sinϕ) -> xrot, yrot

rotate by `-ϕ` about origin

----------------
    unrotate(x,y,shape) -> xrot, yrot

rotate about `shape`'s center by the negative of `shape`'s angle
"""
unrotate(p::Point{2},cosϕ::Real,sinϕ::Real) = rotate(p,cosϕ,-sinϕ)
unrotate(p::Point{2},s::AbstractShape{2}) = s.origin + unrotate(p-s.origin,s.cosϕ,s.sinϕ)
unrotate(p::AbstractArray,s::AbstractShape{2}) = s.origin .+ unrotate(p.-s.origin,s.cosϕ,s.sinϕ)

################################################################################
# UNSYMMETRIC AUXILLIARIES

function build_models(s::AbstractShape{N}) where N
    models = Array{Opt}(undef,N)
    for i ∈ eachindex(models)
        models[i] = Opt(NL_NORMAL_ALGORITHM, 1)
        models[i].xtol_rel = NL_NORMAL_XTOL
        models[i].ftol_rel = NL_NORMAL_FTOL
        models[i].maxeval = NL_NORMAL_MAXEVAL
        if typeof(s)<:AbstractQuadrilateral
            models[i].lower_bounds = 0
            models[i].upper_bounds = 1
        end
    end
    return models
end

function model_objective(v::Vector,grad::Vector,X::Number,Y::Number,s::AbstractShape,side::Int)
    x,y,ẋ,ẏ = perimeter(v[1],s,side)
    if length(grad) > 0
        grad[1] = 2(x-X)*ẋ + 2(y-Y)*ẏ
    end
    return (x-X)^2 + (y-Y)^2
end

"""
    normal_distance(shape,x,y) -> normal, tangent, distance, side

Get the `normal` vector from the surface of `shape` to a point `x,y`,
and the associated `tangent` vector and distance from surface `side`.

The returned arguments are sorted in ascending order by `distance`, so that, e.g.,
`normal[1]` is the normal vector associated with the closest side.
"""
function normal_distance(s::TS,x::Number,y::Number) where TS<:AbstractShape{2}
    n = Vector{Vector{Float64}}(undef,length(s.models))
    d = Vector{Float64}(undef,length(s.models))
    sides = 1:length(s.models)
    for i ∈ eachindex(s.models)
        model = s.models[i]
        model.min_objective = (v,g)->model_objective(v,g,x,y,s,i)
        minf,mint,ret = optimize(model,[t0_shape(x,y,s)])
        X,Y = perimeter(mint[1],s,i)
        n[i] = [x-X, y-Y]
        n[i] = n[i]/norm(n[i])
        d[i] = sqrt(minf)
    end
    perm = sortperm(d)
    n, d = n[perm], d[perm]
    NORMAL = Vector{Vector{Float64}}(undef,length(s.models))
    TANGENT = Vector{Vector{Float64}}(undef,length(s.models))
    for i ∈ eachindex(NORMAL)
        nx, ny = n[i][1],n[i][2]
        NORMAL[i] = [nx, ny]
        TANGENT[i] = [ny,-nx]
    end
    return NORMAL, TANGENT, d, sides[perm]
end

t0_shape(x::Number,y::Number,s::AbstractQuadrilateral) = .5
t0_shape(x::Number,y::Number,s::AbstractDisk) = atan(y-s.origin.y,x-s.origin.x)


################################################################################
# Plotting

import ..SHAPE_COLOR
import ..SHAPE_FILL_ALPHA

# plotting for all disks
@recipe function f(d::AbstractDisk)
    ϕ = LinRange(0,2π,201)
    x = Vector{Float64}(undef,length(ϕ))
    y = Vector{Float64}(undef,length(ϕ))
    for i ∈ eachindex(ϕ) x[i],y[i] = perimeter(ϕ[i],d,1) end
    alpha --> 0
    seriestype --> :path
    fillcolor --> SHAPE_COLOR
    fillrange --> d.origin.y
    fillalpha --> SHAPE_FILL_ALPHA
    aspect_ratio --> 1
    legend-->false
    (x,y)
end

# plot all quadrilaterals
@recipe function f(q::AbstractQuadrilateral)
    t = LinRange(0,1,201)
    x1,y1 = Array{Float64}(undef,length(t)), Array{Float64}(undef,length(t))
    x2,y2 = Array{Float64}(undef,length(t)), Array{Float64}(undef,length(t))
    x3,y3 = Array{Float64}(undef,length(t)), Array{Float64}(undef,length(t))
    x4,y4 = Array{Float64}(undef,length(t)), Array{Float64}(undef,length(t))
    for i ∈ eachindex(t)
        x1[i],y1[i] = perimeter(t[i],q,1)
        x2[i],y2[i] = perimeter(t[i],q,2)
        x3[i],y3[i] = perimeter(t[i],q,3)
        x4[i],y4[i] = perimeter(t[i],q,4)
    end
    alpha --> 0
    seriestype --> :path
    fillcolor --> SHAPE_COLOR
    fillrange --> q.origin.y
    fillalpha --> SHAPE_FILL_ALPHA
    aspect_ratio --> 1
    legend --> false
    vcat(x1,x4,reverse(x3)),vcat(y1,y4,reverse(y3))
end



















#
# """
#     struct Ellipse <: AbstractDisk <: AbstractShape{1}
#
#     Ellipse((a,b), x0, y0, ϕ=0; reference=:center) -> ellipse
#     Ellipse(a, b, x0, y0, ϕ=0; reference=:center) -> ellipse
#
#
# `a, b` axis lengths
# `x0, y0` is location of `reference`
# `ϕ` angle of `a` axis
#
# ----------------
#
#     (::Ellipse)(x,y) -> is_in_ellipse::Bool
# """
# struct Ellipse <: AbstractDisk
#     a::Float64
#     b::Float64
#     x0::Float64
#     y0::Float64
#     ϕ::Float64
#     sinϕ::Float64
#     cosϕ::Float64
#     corners::Tuple{}
#     models::Array{Opt,1}
#
#     Ellipse((a,b),args...;kwargs...) = Ellipse(a,b,args...;kwargs...)
#     function Ellipse(a::Number,b::Number,x0::Number,y0::Number,ϕ::Number=0; reference::Symbol=:center)
#         if reference ∈ [:bottom, :Bottom, :b, :B]
#             x0,y0 = (x0,y0) .+ rotate( 0, b,cos(ϕ),sin(ϕ))
#         elseif reference ∈ [:top, :Top, :T, :t]
#             x0,y0 = (x0,y0) .+ rotate( 0,-b,cos(ϕ),sin(ϕ))
#         elseif reference ∈ [:left, :Left, :L, :l]
#             x0,y0 = (x0,y0) .+ rotate( a, 0,cos(ϕ),sin(ϕ))
#         elseif reference ∈ [:right, :Right, :R, :r]
#             x0,y0 = (x0,y0) .+ rotate(-a, 0,cos(ϕ),sin(ϕ))
#         end
#          e = new(a,b,x0,y0,ϕ,sin(ϕ),cos(ϕ))
#          models = build_models(e)
#          return new(a,b,x0,y0,ϕ,sin(ϕ),cos(ϕ),(),models)
#     end
#
#     Ellipse(c::Circle) = Ellipse(c.R,c.R,c.x0,c.y0,c.ϕ)
#
#     function (e::Ellipse)(x,y)
#         xurot, yurot = unrotate(x, y, e)
#         return hypot((xurot-e.x0)/e.a, (yurot-e.y0)/e.b) < 1-eps()
#     end
#
#     function Base.show(io::IO, ellipse::Ellipse)
#         print(io, "Ellipse(a=", fmt("2.2f",ellipse.a), ", b=", fmt("2.2f",ellipse.b), ", x0=", fmt("2.2f",ellipse.x0), ", y0=", fmt("2.2f",ellipse.y0), ", ϕ=∠", fmt("3.2f",(mod2pi(ellipse.ϕ))*180/π), "°)")
#     end
# end
# function perimeter(t::Number,e::Ellipse,side::Int)
#     sn,cs = sincos(t)
#     xur,yur =    e.a*cs, e.b*sn
#     xpur,ypur = -e.a*sn, e.b*cs
#     x,y = (e.x0,e.y0) .+ rotate(xur,yur,e.cosϕ,e.sinϕ)
#     ẋ,ẏ = rotate(xpur,ypur,e.cosϕ,e.sinϕ)
#     return x,y,ẋ,ẏ
# end
#
#
# """
#     struct DeformedDisk{N} <: AbstractDisk <: AbstractShape{1}
#
#     DeformedDisk{N}(R, x0, y0, M, a, φ, ϕ=0) -> deformeddisk
#     DeformedDisk{N}((R,M,a,φ), x0, y0, ϕ=0) -> deformeddisk
#
# `R` is radius,
# `x0` and `y0` is center of circle of radius `R`,
# `M` is array of length `N` of multipole integers,
# `a` is array of length `N` amplitudes,
# `φ` is array of length `N` of angles
# `ϕ` is overall rotation angle
#
# -----------------
#
#     (::DeformedDisk)(x,y) -> is_in_disk::Bool
# """
# struct DeformedDisk{N} <: AbstractDisk
#     R::Float64
#     x0::Float64
#     y0::Float64
#     ϕ::Float64
#     M::SArray{Tuple{N},Int,1,N}
#     a::SArray{Tuple{N},Float64,1,N}
#     φ::SArray{Tuple{N},Float64,1,N}
#     sinϕ::Float64
#     cosϕ::Float64
#     corners::Tuple{}
#     models::Array{Opt,1}
#
#     DeformedDisk{n}((R,M,a,φ),x0,y0,args...;kwargs...) where n= DeformedDisk{n}(R,x0,y0,M,a,φ,args...;kwargs...)
#     function DeformedDisk{n}(R::Number,x0::Number,y0::Number,M,a,φ,ϕ=0) where n
#         @assert n==length(M)==length(a)==length(φ) "parameter N in DeformedDisk{N}(...) must be equal to length(M)"
#         d = new{n}(R,x0,y0,ϕ,SVector{n}(M),SVector{n}(a),SVector{n}(φ.+ϕ),sin(ϕ),cos(ϕ))
#         models = build_models(d)
#         return new{n}(R,x0,y0,d.ϕ,d.M,d.a,d.φ,d.sinϕ,d.cosϕ,(),models)
#     end
#
#     DeformedDisk(c::Circle) = DeformedDisk{0}(c.R,c.x0,c.y0,[],[],[],c.ϕ)
#
#     function (d::DeformedDisk)(x,y)
#         ϕ = atan(y-d.y0,x-d.x0)
#         r = hypot(x-d.x0,y-d.y0) < d.R + sum(d.a.*(map((m,φ)->cos(m*(ϕ-φ)),d.M,d.φ))) - eps(d.R)
#         return r
#     end
#
#     function Base.show(io::IO, d::DeformedDisk{N}) where N
#          print(io,"DeformedDisk with $N multipoles")
#     end
# end
# function perimeter(t::Number,d::DeformedDisk,side::Int)
#     r = d.R + sum(d.a.*(map((m,φ)->cos(m*(t-φ)),d.M,d.φ)))
#     ṙ = sum(d.a.*(map((m,φ)->-m*sin(m*(t-φ)),d.M,d.φ)))
#     sn,cs = sincos(t)
#     x,y = d.x0 + r*cs, d.y0 + r*sn
#     ẋ = ṙ*cs - r*sn
#     ẏ = ṙ*sn + r*cs
#     return x,y,ẋ,ẏ
# end



# """
#     struct Annulus <: AbstractShape{2}
#
#     Annulus((R1,R2),x0,y0,ϕ=0) -> annulus
#     Annulus(R1, R2, x0, y0, ϕ=0) -> annulus
#
# `R1` is inner radius, `R2` outer
# `x0, y0` is center
#
# -------------
#     (::Annulus)(x,y) -> is_in_annulus::Bool
# """
# struct Annulus <: AbstractShape{2}
#     R1::Float64
#     R2::Float64
#     x0::Float64
#     y0::Float64
#     ϕ::Float64
#     sinϕ::Float64
#     cosϕ::Float64
#     corners::Tuple{}
#     models::Array{Opt,1}
#
#     Annulus((R1,R2),args...;kwargs...) = Annulus(R1,R2,args...;kwargs...)
#     function Annulus(R1::Number,R2::Number,x0::Number,y0::Number,ϕ::Number=0)
#         @assert R1≤R2 "R1=$R1, R2=$R2 must satisfy R1≤R2"
#         a = new(R1,R2,x0,y0,0,0,1)
#         models = build_models(a)
#         return new(R1,R2,x0,y0,0,sin(ϕ),cos(ϕ),(),models)
#     end
#
#     (c::Annulus)(x,y) = c.R1+eps(c.R1) < hypot( (x-c.x0),(y-c.y0) ) < c.R2-eps(c.R2)
#
#     function Base.show(io::IO, a::Annulus)
#         print(io, "Annulus(R1=$(fmt("2.2f",a.R1)), R2=$(fmt("2.2f",a.R2)), x0=$(fmt("2.2f",a.x0)), y0=$(fmt("2.2f",a.y0)))")
#     end
# end
# function perimeter(t::Number,a::Annulus,side::Int)
#     sn,cs = sincos(t)
#     R = side==1 ? a.R1 : a.R2
#     x = a.x0 + R*cs
#     y = a.y0 + R*sn
#     ẋ = -R*sn
#     ẏ =  R*cs
#     return x,y,ẋ,ẏ
# end
# @recipe function f(cr::Annulus)
#     @series Circle(cr.R1,cr.x0,cr.y0)
#     @series Circle(cr.R2,cr.x0,cr.y0)
# end
#
#
#

#
#
# # """
# #     Parallelogram(a, b, α, x0, y0, ϕ)
# # """
# # struct Parallelogram <: AbstractParallelogram
# #     a::Float64
# #     b::Float64
# #     α::Float64
# #     x0::Float64
# #     y0::Float64
# #     ϕ::Float64
# #     sinϕ::Float64
# #     cosϕ::Float64
# #     tanα::Float64
# #     cosα::Float64
# #     models::Array{Opt,1}
# #
# #     function Parallelogram(a::Number, b::Number, α::Number, x0::Number, y0::Number, ϕ::Number)
# #         new(a,b,α,x0,y0,ϕ,cos(ϕ),sin(ϕ),tan(α),cos(α))
# #     end
# #
# #     function (p::Parallelogram)(x,y)
# #         xrot, yrot = rotate(x-p.x0, y-p.y0, p.cosϕ, p.sinϕ)
# #         return p.tanα*(xrot-p.a) < yrot < p.tanα*xrot  &&  0 < yrot < p.cosα*p.b
# #     end
# #
# #     Base.show(io::IO, par::Parallelogram) = print(io, "Parallelogram(a=$(fmt("2.2f",par.a)), b=$(fmt("2.2f",par.b)), α=$(fmt("2.2f",par.α)), x0=$(fmt("2.2f",par.x0)), y0=$(fmt("2.2f",par.y0)), ϕ=$(fmt("2.2f",par.ϕ)))")
# #
# #     @recipe function f(pg::Parallelogram)
# #         x = cumsum([0, pg.a, +pg.b*cos(pg.α), -pg.a, -pg.b*cos(pg.α)])
# #         y = cumsum([0, 0, +pg.b*sin(pg.α), 0, -pg.b*sin(pg.α)])
# #         alpha --> 0
# #         seriestype --> :path
# #         fillcolor --> SHAPE_COLOR
# #         fillrange --> 0
# #         fillalpha --> SHAPE_FILL_ALPHA
# #         aspect_ratio --> 1
# #         legend --> false
# #         xrot, yrot = rotate(x,y,pg.cosϕ,-pg.sinϕ)
# #         pg.x0 .+ xrot, pg.y0 .+ yrot
# #     end
# # end
#
