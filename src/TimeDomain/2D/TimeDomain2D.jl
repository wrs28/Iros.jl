module TimeDomain2D

using ..Common
using ..DivGradCurls
using Plots
using ProgressMeter
using RecipesBase

import ..Common.DEFAULT_CFL_NUMBER
import ..Common.AbstractComplexBL
import LinearAlgebra: mul!

import ..AbstractFDTD
import ..AbstractFields
import ..HelmholtzPointSource
import ..HelmholtzWaveFields
import ..HelmholtzFDTD
import ..propagate!
import .._αβ
import .._whichdimspml
import .._ndimpml


# HelmholtzField constructor from simulation
"""
    HelmholtzWaveFields(simulation) -> hf
"""
HelmholtzWaveFields

function HelmholtzWaveFields(sim::Simulation{2,Common.Symmetric})
    M = _ndimpml(sim)
    if M==0
        φ = (ScalarField(sim.x, 1, Float64), ScalarField(sim.x, 1, Float64))
        ∇Φₓ = (ScalarField(sim.x_half[1], 1, Float64), ScalarField(sim.x_half[1], 1, Float64))
        ∇Φᵤ = (ScalarField(sim.x_half[2], 1, Float64), ScalarField(sim.x_half[2], 1, Float64))
        ∇Φ = ((∇Φₓ[1], ∇Φᵤ[1]),(∇Φₓ[2], ∇Φᵤ[2]))
    elseif M==1
        φ = (ScalarField(sim.x, 1, Float64), ScalarField(sim.x, 1, Float64))
        ∇Φₓ = (ScalarField(sim.x_half[1], 1, Float64), ScalarField(sim.x_half[1], 1, Float64))
        ∇Φᵤ = (ScalarField(sim.x_half[2], 1, Float64), ScalarField(sim.x_half[2], 1, Float64))
        ∇Φ = (∇Φₓ, ∇Φᵤ)
    else
        φ = (ScalarField(sim.x, 1, Float64), ScalarField(sim.x, 1, Float64), ScalarField(sim.x, 1, Float64))
        ∇Φₓ = (ScalarField(sim.x_half[1], 1, Float64), ScalarField(sim.x_half[1], 1, Float64), ScalarField(sim.x_half[1], 1, Float64))
        ∇Φᵤ = (ScalarField(sim.x_half[2], 1, Float64), ScalarField(sim.x_half[2], 1, Float64), ScalarField(sim.x_half[2], 1, Float64))
        ∇Φ = (∇Φₓ, ∇Φᵤ)
    end
    return HelmholtzWaveFields(φ, ∇Φ)
end


"""
    HelmholtzFDTD(sim; source=0, dt=sim.dx*$DEFAULT_CFL_NUMBER, plotoptions...) -> fdtd
"""
function HelmholtzFDTD(
            sim::Simulation{2,Common.Symmetric},
            source = HelmholtzPointSource(sim, 1e100, 0);
            dt::Real = 1/(1/sim.dx+1/sim.dy)*DEFAULT_CFL_NUMBER,
            kwargs...)

    return HelmholtzFDTD(sim, source, dt; kwargs...)
end


function _ndimpml(sim::Simulation{2})
    bls = sim.boundary.bls
    if typeof(bls[1])<:AbstractComplexBL || typeof(bls[2])<:AbstractComplexBL
        if typeof(bls[3])<:AbstractComplexBL || typeof(bls[4])<:AbstractComplexBL
            ndim = 2
        else
            ndim = 1
        end
    else
        if typeof(bls[3])<:AbstractComplexBL || typeof(bls[4])<:AbstractComplexBL
            ndim = 1
        else
            ndim = 0
        end
    end
    return ndim
end


function _whichdimspml(sim::Simulation{2,Common.Symmetric})
    M = _ndimpml(sim)
    if M == 0
        return ()
    elseif M==1
        if typeof(sim.boundary.bls[1])<:AbstractComplexBL || typeof(sim.boundary.bls[2])<:AbstractComplexBL
            return (1,)
        else
            return (2,)
        end
    elseif M==2
        return (1,2)
    end
end

function _αβ(sim::Simulation{2,Common.Symmetric}, dt::Real)
    M = _ndimpml(sim)
    pmldims = _whichdimspml(sim)
    if M == 0
        α = [ones(Float64,length(sim)), dt./sim.ε]
        β = [ones(Float64,length(sim)), fill(dt,length(sim))]
    elseif M==1
    elseif M==2
    end
    return α, β
end


"""
    HelmholtzPointSource(sim, xoft) -> ps
"""
function HelmholtzPointSource(sim::Simulation{2,Common.Symmetric}, xoft, aoft, ωoft=1, ϕoft=0) where F
    σ = 4hypot(sim.dx,sim.dy)
    N = sqrt(2π)*σ
    return HelmholtzPointSource(xoft, aoft, ωoft, ϕoft, σ^2, N)
end

"""
    propagate!(fdtd, [n=1; animate=false, verbose=false])
"""
@inline function propagate!(fdtd::HelmholtzFDTD{2,2,0}, n::Integer=1; animate::Bool=false, verbose::Bool=false)
    dt = fdtd.dt

    φ = getfield(fdtd.fields,:φ)
    ∇Φ = fdtd.fields.∇Φ

    grad = fdtd.grad
    div = fdtd.div

    α = fdtd.α
    β = fdtd.β

    options = fdtd.options

    verbose ? pg = Progress(n) : nothing
    foreach(1:n) do i
        @fastmath mul!(φ[2], div, ∇Φ[1])
        @fastmath @inbounds @simd for j ∈ eachindex(φ[1])
            φ[1][j] = α[1][j]*φ[1][j] + α[2][j]*φ[2][j]
            iszero(fdtd.source.aoft(fdtd.t[1])) ? nothing : φ[1][j] -= dt*fdtd.source(φ[1].positions[j], fdtd.t[1])
        end
        @fastmath @inbounds fdtd.t[1] += dt/2

        @fastmath mul!(∇Φ[2], grad, φ[1])
        for k ∈ eachindex(∇Φ[1])
            @fastmath @inbounds @simd for j ∈ eachindex(∇Φ[1][k])
                ∇Φ[1][k][j] = β[1][j]*∇Φ[1][k][j] + β[2][j]*∇Φ[2][k][j]
            end
        end
        @fastmath @inbounds fdtd.t[1] += dt/2

        verbose ? next!(pg) : nothing

        if animate && iszero(mod(fdtd.n[1]+i-options.start,options.interval))
            if options.by ∈ (abs,abs2)
                options.ylims[1] = 0
                options.ylims[2] = max(options.ylims[2],maximum(options.by,φ[1]))
            else
                options.ylims[1] = min(options.ylims[1],minimum(options.by,φ[1]))
                options.ylims[2] = max(options.ylims[2],maximum(options.by,φ[1]))
                options.ylims[2] = max(abs(options.ylims[1]),abs(options.ylims[2]))
                options.ylims[1] = -options.ylims[2]
            end
            frame(options.animation, plot(fdtd, options.by; ylims=options.ylims, grid=false, options.plotoptions...))
        end
    end
    fdtd.n[1] += n
    return nothing
end


################################################################################
# Plotting

@recipe function f(field::HelmholtzWaveFields{2,2}, by::Function)
    @series begin field.φ, by end
end
@recipe function f(sim::Simulation{2}, field::HelmholtzWaveFields{1,2}, by::Function)
    @series begin sim, field.φ, by end
end

@recipe function f(fdtd::HelmholtzFDTD{2,2}, by::Function)
    @series begin fdtd.fields, by end
end
@recipe function f(sim::Simulation{2}, fdtd::HelmholtzFDTD{2,2}, by::Function)
    @series begin fdtd.simulation, fdtd.fields, by end
end

end # module

using .TimeDomain2D
