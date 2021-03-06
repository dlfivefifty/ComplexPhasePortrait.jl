module ComplexPhasePortrait
using RecipesBase, Plots
import Images
import Colors: RGB, HSL

export portrait,
       PTproper, PTcgrid, PTstepphase, PTstepmod, phaseplot

abstract type PortraitType <: Any end
struct PTproper <: PortraitType end
struct PTcgrid <: PortraitType end
struct PTstepmod <: PortraitType end
struct PTstepphase <: PortraitType end

const brighten = 0.1

"""
portrait builds a phase portrait over a give complex grid.

The PortraitType determines what type of portrait is generated:

* PTproper - a proper phase portrait
* PTcgrid - a conformal grid
* PTstepphase - a stepped phase plot
* PTstepmod - a stepped modulus plot

Named arguments:

* ctype - is the colormap type. The default "standard" is a basic HSL map
  with H∈[0,360], S = 1.0, and L = 0.5. Setting `ctype="nist"` gives the
  [NIST color scheme](http://dlmf.nist.gov/help/vrml/aboutcolor).
* pres - is the phase step resolution (number of phase jumps), default
  `pres=20`.
"""

function portrait(fval::Array{Complex{Float64},2}; kwargs...)
    portrait(fval, PTproper; kwargs...)
end

function portrait(fval::Array{Complex{Float64},2}, ::Type{PTproper};
                  kwargs...)
    args = baseArgs(fval; kwargs...)
    phaseToImage!(args[1:3]...)
    return args[1]
end

function portrait(fval::Array{Complex{Float64},2}, ::Type{PTcgrid};
                  pres=20, kwargs...)
    (img, nphase, cm, farg) = baseArgs(fval; kwargs...)
    lowb = sqrt(0.75^2*(1.0 - brighten) + brighten)
    black = (sawfun(farg, 1/pres, lowb, 1.0)
             .*sawfun(log(abs(fval)), 2pi/pres, lowb, 1.0))
    phaseToImage!(img, nphase, black, cm)
    return img
end

function portrait(fval::Array{Complex{Float64},2}, ::Type{PTstepmod};
                  pres=20, kwargs...)
    (img, nphase, cm) = baseArgs(fval; kwargs...)
    phaseToImage!(img, nphase, sawfun(log.(abs.(fval)), 2pi/pres, 0.75, 1.0), cm)
    return img
end

function portrait(fval::Array{Complex{Float64},2}, ::Type{PTstepphase};
                  pres=20, kwargs...)
    (img, nphase, cm, farg) = baseArgs(fval; kwargs...)
    phaseToImage!(img, nphase, sawfun(farg, 1/pres, 0.75, 1.0), cm)
    return img
end

function baseArgs(fval::Array{Complex{Float64},2}; kwargs...)
    (farg, nphase, cm) = setupPhase(fval; kwargs...)
    (m, n) = size(nphase)
    img = Array{RGB{Float64}}(m, n)
    return img, nphase, cm, farg
end

function setupPhase(fval; kwargs...)
    cm = baseColorMap(;kwargs...)
    nc = length(cm)
    farg = (angle.(-fval) .+ pi)./2pi
    nphase = stepfun(farg, nc)

    return (farg, nphase, cm)
end

"Color map for complex phase portrait with 600 elements."
function baseColorMap(;ctype="standard")
    if ctype == "nist"
        const nc = 900
        cm = linspace(HSL(0.0, 1.0, 0.5), HSL(360.0, 1.0, 0.5), nc)
        idx = [1:Int(nc/6); Int(nc/6)+1:2:Int(nc/2); Int(nc/2)+1:2*Int(nc/3);
              2*Int(nc/3)+1:2:nc]
        cm = cm[idx]
    else
        cm = linspace(HSL(0.0, 1.0, 0.5), HSL(360.0, 1.0, 0.5), 600)
    end
    cm = convert(Array{RGB{Float64}}, cm)
end

"Integer step function with period 1 such that [0,1]⟶[1,nmax]."
function stepfun(x, nmax)
    y = x .- floor.(x)
    y = convert(Array{UInt16}, floor.(nmax*y) .+ 1)
end

"Sawtooth function over reals with period dx onto [a,b]."
function sawfun(x, dx, a, b)
    x = x/dx
    x = x .- floor.(x)
    x = a .+ (b - a)*x
end

function phaseToImage!(img, pidx, cm)
    n = size(pidx, 1)
    for j in 1:size(pidx, 2), i in 1:n
        img[n-i+1,j] = cm[pidx[i,j]]
    end
    nothing
end

function phaseToImage!(img, pidx, black, cm)
    n = size(pidx, 1)
    for j in 1:size(pidx, 2), i in 1:n
        img[n-i+1,j] = cm[pidx[i,j]]*black[i,j]
    end
    nothing
end

## Recipe for Plots

# @userplot PhasePlot
#
# @recipe function f(c::PhasePlot)
#     if length(c.args) < 3 || !(c.args[1] isa Function)
#         error("Complex Plot requires a complex function")
#     end
#
#     ff = c.args[1]
#
#     xx = if c.args[2] isa AbstractVector
# 	    	c.args[2]
#     	elseif c.args[2] isa NTuple{2,Int}
#     		linspace(c.args[2]..., 500)
#     	else
#     		error("Complex plot second argument must give the x limits")
# 		end
#     yy = if c.args[3] isa AbstractVector
# 	    	c.args[3]
#     	elseif c.args[3] isa NTuple{2,Int}
#     		linspace(c.args[3]..., 500)
#     	else
#     		error("Complex plot tihrtd argument must give the y limits")
# 		end
#
#
#
#     zz = xx' .+ im.*yy
#
#     xlims := (first(xx),last(xx))
#     ylims := (first(yy),last(yy))
#     yflip := false
#
#     @series portrait(Matrix{Complex128}(ff.(zz)))
# end


function phaseplot(f, xx::AbstractVector, yy::AbstractVector; kwds...)
    zz = xx' .+ im.*yy
    F = f.(zz)[end:-1:1, :]

    plt = plot(portrait(Matrix{Complex128}(F));
                xlims=(first(xx),last(xx)),
                ylims=(first(yy),last(yy)), kwds...)
    plt.subplots[1][:yaxis][:flip] = false
    plt
end

phaseplot(f, xx::NTuple{2,Int}, yy::NTuple{2,Int}; kwds...) =
    phaseplot(f, linspace(xx..., 500), linspace(yy..., 500); kwds...)




end # module
