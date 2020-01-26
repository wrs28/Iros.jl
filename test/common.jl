using Iris
using Test

@testset "Common" begin
    include("Common/points.jl")
    include("Common/vectorfields.jl")
    include("Common/shapes.jl")
    include("Common/boundarylayers.jl")
    include("Common/boundaryconditions.jl")
    include("Common/boundaries.jl")
    include("Common/dielectricfunctions.jl")
    include("Common/pumpfunctions.jl")
    include("Common/lattices.jl")
    include("Common/dispersions.jl")
    include("Common/domains.jl")
    include("Common/laplacians.jl")
    # include("Common/curlcurls.jl")
    include("Common/selfenergies.jl")
    include("Common/simulations.jl")
    include("Common/helmholtzoperators.jl")
    include("Common/lufactorizations.jl")
end
