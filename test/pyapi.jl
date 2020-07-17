@testset "pyapi" begin

    function _testsuite(api)
        @testset "Read API" begin
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

        @testset "Write API" begin
            write_estimate(api, "parameter", "example-estimate", 99.0)
            @test read_estimate(api, "parameter", "example-estimate") == 99.0

            @testset "Write $d" for d in (Gamma(4, 5), Normal(4, 5))
                write_distribution(api, "parameter", "example-distribution", d)
                @test read_distribution(api, "parameter", "example-distribution") == d
            end

            write_samples(api, "parameter", "example-samples", [9, 10, 11])
            @test read_sample(api, "parameter", "example-samples") ∈ [9, 10, 11]

            df = DataFrame(:a => [9, 10], :b => [11, 12])
            write_table(api, "object", "example-table", df)
            @test_broken read_table(api, "object", "example-table") == df

            write_array(api, "object", "example-array", [4, 5, 6])
            expected_array = (data=[4, 5, 6], dimensions=nothing, units=nothing)
            @test_broken read_array(api, "object", "example-array") == expected_array
        end
    end

    mktempdir() do tempdir
        datadir = mkdir(joinpath(tempdir, "data"))
        config = joinpath(datadir, "config.yaml")
        accessfile = joinpath(datadir, "access-example.yaml")
        remove_accessfile() = rm(accessfile, force=true)

        # Fresh copy of data for each testset because we will be writing stuff
        @testset "Basic syntax" begin
            cp("data", datadir; force=true)
            remove_accessfile()
            api = StandardAPI(config, "test_uri", "test_git_sha")
            _testsuite(api)
            # Need to manually close to write out access file
            @test !isfile(accessfile)
            close(api)
            @test isfile(accessfile)
            remove_accessfile()
        end

        @testset "do-block syntax" begin
            cp("data", datadir; force=true)
            remove_accessfile()
            StandardAPI(config, "test_uri", "test_git_sha") do api
                _testsuite(api)
            end
            @test isfile(accessfile)
            remove_accessfile()
        end

        @testset "Issue logging" begin
            cp("data", datadir; force=true)
            remove_accessfile()
            StandardAPI(config, "test_uri", "test_git_sha") do api
                issues = [
                    DataPipelineIssue("test issue 1", 1),
                    DataPipelineIssue("test issue 2", 2),
                ]
                write_estimate(api, "parameter", "example-estimate", 1.0; issues=issues)
            end
            access_yaml = YAML.load_file(accessfile)
            @test access_yaml["io"][1]["call_metadata"]["issues"] == [
                Dict("description"=>"test issue 1", "severity"=>1),
                Dict("description"=>"test issue 2", "severity"=>2),
            ]
            @test access_yaml["io"][1]["access_metadata"]["issues"] == [
                Dict("description"=>"test issue 1", "severity"=>1),
                Dict("description"=>"test issue 2", "severity"=>2),
            ]
            remove_accessfile()
        end

        @testset "Descriptions" begin
            cp("data", datadir; force=true)
            remove_accessfile()
            StandardAPI(config, "test_uri", "test_git_sha") do api
                write_estimate(
                    api, "parameter", "example-estimate", 1.0;
                    description="test description"
                )
            end
            access_yaml = YAML.load_file(accessfile)
            @test access_yaml["io"][1]["call_metadata"]["description"] == "test description"
            @test access_yaml["io"][1]["access_metadata"]["description"] == "test description"
            remove_accessfile()
        end
    end
end
