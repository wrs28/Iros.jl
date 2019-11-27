using Arpack

"""
    eigs(lep::MaxwellLEP, ω, [ωs, ψs; nev=6, ncv=max(20,2*nev+1), which=:LM, tol=0.0, maxiter=300, sigma=ω², ritzvec=true, v0=zeros((0,))])

if frequencies `ωs::Vector` and fields `ψs::ElectricField` are provided, susceptability is *saturated*
"""
function Arpack.eigs(lep::MaxwellLEP, ω::Number, args...; kwargs...)
    A, B = lep(ω, args...)
    ω², ψ, nconv, niter, nmult, resid = eigs(spdiagm(0=>1 ./diag(B))*A; kwargs..., sigma=ω^2)
    return sqrt.(ω²), ElectricField(lep,ψ), nconv, niter, nmult, resid
end

"""
    eigs(cf::MaxwellCF, ω, [ωs, ψs; η=0, nev=6, ncv=max(20,2*nev+1), which=:LM, tol=0.0, maxiter=300, sigma=η, ritzvec=true, v0=zeros((0,))])

if frequencies `ωs::Vector` and fields `ψs::ElectricField` are provided, susceptability is *saturated*
"""
function Arpack.eigs(cf::MaxwellCF, ω::Number, args...; η::Number=0, kwargs...)
    A, B = cf(ω, args...)
    ηs, u, nconv, niter, nmult, resid = eigs(A, B; kwargs..., sigma=η)
    return ηs, ElectricField(cf, u), nconv, niter, nmult, resid
end

function maxwelleigen_arpack(
            lep::MaxwellLEP,
            ω::Number,
			args...;
            verbose::Bool=false,
            kwargs...)

	ωs, ψs, nconv, niter, nmult, resid = eigs(lep, ω, args...; kwargs...)
    length(ωs) ≤ nconv || @warn "$(length(ωs) - nconv) evecs did not converge"
    normalize!(lep.simulation, ψs.values, lep.αεpFχ, size(ψs,1)÷2+INDEX_OFFSET) # Normalize according to (ψ₁,ψ₂)=δ₁₂
	orthogonalize!(ψs,lep.simulation, ωs, lep.αεpFχ, lep.ky, lep.kz)
	if all(iszero,(lep.ky,lep.kz)) normalize!(lep.simulation, ψs.values, lep.αεpFχ, size(ψs,1)÷2+INDEX_OFFSET) end
	return ωs, ψs
end

if DEFAULT_LINEAR_EIGENSOLVER == :Arpack
@doc """
$doc_lep
`nev` Number of eigenvalues (`6`);
`v0` Starting vector (`zeros((0,))`);
`maxiter` Maximum iterations (`300`);
`ncv` Number of Krylov vectors (`max(20,2*nev+1)`);
`tol` Tolerance is max of ε and `tol` (`0.0`);
"""
maxwelleigen(lep::MaxwellLEP, args...;kwargs...) = maxwelleigen_arpack(lep,args...;kwargs...)
end


function maxwelleigen_arpack(
            cf::MaxwellCF,
            ω::Number,
			args...;
			η::Number = 0,
            verbose::Bool=false,
            kwargs...)

	ηs, us, nconv, niter, nmult, resid = eigs(cf, ω, args...; kwargs...)
    length(ηs) ≤ nconv || @warn "$(length(ηs) - nconv) evecs did not converge"
    normalize!(cf.simulation, us, cf.F) # Normalize according to (ψ₁,ψ₂)=δ₁₂
	orthogonalize!(us,cf.simulation, ηs, cf.F, cf.ky, cf.kz)
	if all(iszero,(cf.ky,cf.kz)) normalize!(cf.simulation, us, cf.F) end
	return ηs, us
end

if DEFAULT_LINEAR_EIGENSOLVER == :Arpack
	@doc """
	$doc_cf
	`nev` Number of eigenvalues (`6`);
	`v0` Starting vector (`zeros((0,))`);
	`maxiter` Maximum iterations (`300`);
	`ncv` Number of Krylov vectors (`max(20,2*nev+1)`);
	`tol` Tolerance is max of ε and `tol` (`0.0`);
	""" ->
	maxwelleigen(cf::MaxwellCF, args...;kwargs...) = maxwelleigen_arpack(cf,args...;kwargs...)
end
