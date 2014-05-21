# Tests on Multivariate Normal distributions

import PDMats: ScalMat, PDiagMat, PDMat

using Distributions
using Base.Test

##### construction, basic properties, and evaluation

mu = [1., 2., 3.]
va = [1.2, 3.4, 2.6]
C = [4. -2. -1.; -2. 5. -1.; -1. -1. 6.]

x1 = [3.2, 1.8, 2.4]
x = rand(3, 100)

# SGauss

gs = gmvnormal(mu, sqrt(2.0))
@test isa(gs, IsoNormal)
@test dim(gs) == 3
@test mean(gs) == mode(gs) == mu
@test_approx_eq cov(gs) diagm(fill(2.0, 3))
@test var(gs) == diag(cov(gs))
@test_approx_eq entropy(gs) 0.5 * logdet(2π * e * cov(gs))

gsz = gmvnormal(3, sqrt(2.0))
@test isa(gsz, IsoNormal)
@test dim(gsz) == 3
@test mean(gsz) == zeros(3)
@test gsz.zeromean

# DGauss

gd = gmvnormal(mu, sqrt(va))
@test isa(gd, DiagNormal)
@test dim(gd) == 3
@test mean(gd) == mode(gd) == mu
@test_approx_eq cov(gd) diagm(va)
@test var(gd) == diag(cov(gd))
@test_approx_eq entropy(gd) 0.5 * logdet(2π * e * cov(gd))

gdz = gmvnormal(PDiagMat(va))
@test isa(gdz, DiagNormal)
@test dim(gdz) == 3
@test mean(gdz) == zeros(3)
@test gdz.zeromean

# Gauss

gf = MvNormal(mu, C)
@test isa(gf, MvNormal)
@test dim(gf) == 3
@test mean(gf) == mode(gf) == mu
@test cov(gf) == C
@test var(gf) == diag(cov(gf))
@test_approx_eq entropy(gf) 0.5 * logdet(2π * e * cov(gf))

gfz = MvNormal(C)
@test isa(gfz, MvNormal)
@test dim(gfz) == 3
@test mean(gfz) == zeros(3)
@test gfz.zeromean


##### LogPDF/PDF evaluation

@test_approx_eq_eps logpdf(gs, x1) -5.106536370454 1.0e-8
@test_approx_eq_eps logpdf(gd, x1) -6.029399605174 1.0e-8
@test_approx_eq_eps logpdf(gf, x1) -5.680452770982 1.0e-8

@test_approx_eq_eps logpdf(gsz, x1) -8.606536370454 1.0e-8
@test_approx_eq_eps logpdf(gdz, x1) -9.788449378930 1.0e-8
@test_approx_eq_eps logpdf(gfz, x1) -9.621416626404 1.0e-8


n = size(x, 2)
r = zeros(n)

for i = 1:n; r[i] = logpdf(gs, x[:,i]); end
@test_approx_eq logpdf(gs, x) r
@test_approx_eq pdf(gs, x) exp(r)

for i = 1:n; r[i] = logpdf(gsz, x[:,i]); end
@test_approx_eq logpdf(gsz, x) r
@test_approx_eq pdf(gsz, x) exp(r)

for i = 1:n; r[i] = logpdf(gd, x[:,i]); end
@test_approx_eq logpdf(gd, x) r
@test_approx_eq pdf(gd, x) exp(r)

for i = 1:n; r[i] = logpdf(gdz, x[:,i]); end
@test_approx_eq logpdf(gdz, x) r
@test_approx_eq pdf(gdz, x) exp(r)

for i = 1:n; r[i] = logpdf(gf, x[:,i]); end
@test_approx_eq logpdf(gf, x) r
@test_approx_eq pdf(gf, x) exp(r)

for i = 1:n; r[i] = logpdf(gfz, x[:,i]); end
@test_approx_eq logpdf(gfz, x) r
@test_approx_eq pdf(gfz, x) exp(r)


##### Sampling 

x = rand(gs)
@test isa(x, Vector{Float64})
@test length(x) == dim(gs)

x = rand(gd)
@test isa(x, Vector{Float64})
@test length(x) == dim(gd)

x = rand(gf)
@test isa(x, Vector{Float64})
@test length(x) == dim(gf)

x = rand(gsz)
@test isa(x, Vector{Float64})
@test length(x) == dim(gsz)

x = rand(gdz)
@test isa(x, Vector{Float64})
@test length(x) == dim(gdz)

x = rand(gfz)
@test isa(x, Vector{Float64})
@test length(x) == dim(gfz)

n = 10
x = rand(gs, n)
@test isa(x, Matrix{Float64})
@test size(x) == (dim(gs), n)

x = rand(gd, n)
@test isa(x, Matrix{Float64})
@test size(x) == (dim(gd), n)

x = rand(gf, n)
@test isa(x, Matrix{Float64})
@test size(x) == (dim(gf), n)

x = rand(gsz, n)
@test isa(x, Matrix{Float64})
@test size(x) == (dim(gsz), n)

x = rand(gdz, n)
@test isa(x, Matrix{Float64})
@test size(x) == (dim(gdz), n)

x = rand(gfz, n)
@test isa(x, Matrix{Float64})
@test size(x) == (dim(gfz), n)


##### MLE

# a slow but safe way to implement MLE for verification

function _gauss_mle(x::Matrix{Float64})
	mu = vec(mean(x, 2))
	z = x .- mu
	C = (z * z') * (1/size(x,2))
	return mu, C
end

function _gauss_mle(x::Matrix{Float64}, w::Vector{Float64})
	sw = sum(w)
	mu = (x * w) * (1/sw)
	z = x .- mu
	C = (z * scale(w, z')) * (1/sw)
	Base.LinAlg.copytri!(C, 'U') 
	return mu, C
end

x = randn(3, 200) .+ randn(3) * 2.
w = rand(200)

g = fit(MvNormal, x)
mu, C = _gauss_mle(x)
@test_approx_eq mean(g) mu
@test_approx_eq cov(g) C

g = fit_mle(MvNormal, x, w)
mu, C = _gauss_mle(x, w)
@test_approx_eq mean(g) mu
@test_approx_eq cov(g) C

g = fit(IsoNormal, x)
mu, C = _gauss_mle(x)
@test_approx_eq g.μ mu
@test_approx_eq g.Σ.value mean(diag(C))

g = fit_mle(IsoNormal, x, w)
mu, C = _gauss_mle(x, w)
@test_approx_eq g.μ mu
@test_approx_eq g.Σ.value mean(diag(C))

assumed_g = Distributions.IsoNormalKnownSigma(3, 1.)
g = fit_mle(assumed_g, x, w)
mu, C = _gauss_mle(x, w)
@test_approx_eq g.μ mu
@test_approx_eq diag(g.Σ) diag(assumed_g.Σ)

g = fit(DiagNormal, x)
mu, C = _gauss_mle(x)
@test_approx_eq g.μ mu
@test_approx_eq g.Σ.diag diag(C)

g = fit_mle(DiagNormal, x, w)
mu, C = _gauss_mle(x, w)
@test_approx_eq g.μ mu
@test_approx_eq g.Σ.diag diag(C)


##### Sufficient statistics type
n = 3
X = reshape(Float64[1:12], 4, n)
w = rand(n)
Xw = X * diagm(w)

ss = suffstats(MvNormal, X)
ssw = suffstats(MvNormal, X, w)

s_t = sum(X, 2)
ws_t = sum(Xw, 2)
tmp = X .- (s_t ./ n)
ss_t = tmp*tmp'

tmp = X .- sum(Xw, 2) ./ sum(w)
wss_t = (tmp*diagm(w))*tmp'
tw_t = length(w)
wtw_t = sum(w)

@test_approx_eq ss.s s_t
@test_approx_eq ss.m (s_t ./ n)
@test_approx_eq ss.s2 ss_t
@test_approx_eq ss.tw tw_t

@test_approx_eq ssw.s ws_t
@test_approx_eq ssw.m (ws_t ./ wtw_t)
@test_approx_eq ssw.s2 wss_t
@test_approx_eq ssw.tw wtw_t

