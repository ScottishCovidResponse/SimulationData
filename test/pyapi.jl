@testset "pyapi" begin
    config = joinpath("data", "config.yaml")

    function _testsuite(api)
        @test read_estimate(api, "parameter", "example-estimate") == 1.0
        @test read_estimate(api, "parameter", "example-distribution") == 2.0
        @test read_estimate(api, "parameter", "example-samples") == 2.0

        # print(api.read_distribution("parameter", "example-estimate"))  # expected to fail
        @test read_distribution(api, "parameter", "example-distribution") == Gamma(1.0, 2.0)
        # print(api.read_distribution("parameter", "example-samples"))  # expected to fail

        @test read_sample(api, "parameter", "example-estimate") == 1.0
        @test read_sample(api, "parameter", "example-distribution") isa Real
        @test read_sample(api, "parameter", "example-samples") ∈ [1, 2, 3]

        expected_table = DataFrame(:a => [1, 2], :b => [3, 4])
        expected_array = (data=[1, 2, 3], dimensions=nothing, units=nothing)
        @test read_table(api, "object", "example-table") == expected_table
        @test read_array(api, "object", "example-array") == expected_array
    end

    @testset "Basic syntax" begin
        _testsuite(StandardAPI(config))
    end

    @testset "do-block syntax" begin
        StandardAPI(config) do api
            _testsuite(api)
        end
    end
end
