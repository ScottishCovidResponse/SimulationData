@testset "DataBlocks" begin

    deps = datadep"DataBlock-TestFile-ScotPop-v1"
    fpath = joinpath(deps, "Media_722506_smxx.h5")

    scotpop = h5open(fpath, "r") do file
        read(file, "scotpop")
    end

    @test isapprox(sum(scotpop[findall(.!(isnan.(scotpop)))]), 5.45e6; rtol = 1e-3)

end
