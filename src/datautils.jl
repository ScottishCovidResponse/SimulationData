function fetch_data(remote_path, local_dir)
    return string(
        download(
            remote_path,
            joinpath(local_dir, basename(remote_path))
        )
    )
end


# p = Pkg.TOML.parsefile(joinpath(datadep"TestFile-Parameters", "Media_722505_smxx.toml"))
#
#
#
# function validate! end
#
# function describe end
#
# function name end
#
# p = Pkg.TOML.parsefile("Media_722505_smxx.toml")
#
# _unit = p["params"]["unit"]
# β_env = p["params"]["beta_env"]
# β_force = p["params"]["beta_force"]
#
# β_env = uparse("$(β_env) $(_unit)", unit_context = Simulation.Units)
# β_force = uparse("$(β_force) $(_unit)", unit_context = Simulation.Units)
#
# @test β_env isa Unitful.Quantity
# @test β_env == 1.0/day
#
# @test β_force isa Unitful.Quantity
# @test β_force == 1.0/day
#
#
# scotpop = h5open("Media_722506_smxx.h5", "r") do file
#     read(file, "scotpop")
# end
#
# @test isapprox(sum(scotpop[findall(.!(isnan.(scotpop)))]), 5.45e6; rtol = 1e-3)
