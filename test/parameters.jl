@testset "ParameterBlocks" begin

    deps = datadep"ParameterBlock-TestFile-Parameters-v1"
    fpath = joinpath(deps, "Media_722505_smxx.toml")

    p = Pkg.TOML.parsefile(fpath)

    _unit = p["params"]["unit"]
    β_env = p["params"]["beta_env"]
    β_force = p["params"]["beta_force"]

    β_env = uparse("$(β_env) $(_unit)", unit_context = EpiUnits)
    β_force = uparse("$(β_force) $(_unit)", unit_context = EpiUnits)

    @test β_env isa Unitful.Quantity
    @test β_env == 1.0/day

    @test β_force isa Unitful.Quantity
    @test β_force == 1.0/day
end
