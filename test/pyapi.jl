@testset "pyapi" begin
    config = joinpath("data", "config.yaml")
    
    StandardAPI(config) do api
        @test read_estimate(api, "parameter", "example-estimate") == 1.0
        @test read_estimate(api, "parameter", "example-distribution") == 2.0
        @test read_estimate(api, "parameter", "example-samples") == 2.0

        # print(api.read_distribution("parameter", "example-estimate"))  # expected to fail
        @test read_distribution(api, "parameter", "example-distribution") == Gamma(1.0, 2.0)
        # print(api.read_distribution("parameter", "example-samples"))  # expected to fail

        # TODO implement these
        @test_broken read_sample(api, "parameter", "example-estimate")
        @test_broken read_sample(api, "parameter", "example-distribution")
        @test_broken read_sample(api, "parameter", "example-samples")

        expected_table = DataFrame(:a => [1, 2], :b => [3, 4])
        expected_array = [1, 2, 3]
        @test read_table(api, "object", "example-table") == expected_table
        @test read_array(api, "object", "example-array") == expected_array
    end
end
