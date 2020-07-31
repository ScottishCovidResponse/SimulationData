@testset "pyapi" begin

    function _testsuite(api)
        @testset "Read API" begin
            @test read_estimate(api, "parameter-read", "example-estimate") == 1.0
            @test read_estimate(api, "parameter-read", "example-distribution") == 2.0
            @test read_estimate(api, "parameter-read", "example-samples") == 2.0

            # print(api.read_distribution("parameter-read", "example-estimate"))  # expected to fail
            @test read_distribution(api, "parameter-read", "example-distribution") == Gamma(1.0, 2.0)
            # print(api.read_distribution("parameter-read", "example-samples"))  # expected to fail

            @test read_samples(api, "parameter-read", "example-samples") == [1.0, 2.0, 3.0]

            expected_table = DataFrame(:a => [1, 2], :b => [3, 4])
            expected_array = DataPipelineArray([1, 2, 3])
            @test read_table(api, "object-read", "example-table") == expected_table
            read_result = read_array(api, "object-read", "example-array")
            @test read_result == expected_array
        end

        @testset "Write API" begin
            # Can't read it before we've written it
            @test_throws Exception read_estimate(api, "parameter-write", "example-estimate")
            write_estimate(api, "parameter-write", "example-estimate", 99.0)
            @test read_estimate(api, "parameter-write", "example-estimate") == 99.0

            @test_throws Exception read_estimate(api, "parameter-write", "example-distribution")
            @testset "Write $d" for d in (Gamma(4, 5), Normal(4, 5))
                write_distribution(api, "parameter-write", "example-distribution", d)
                @test read_distribution(api, "parameter-write", "example-distribution") == d
            end

            @test_throws Exception read_estimate(api, "parameter-write", "example-samples")
            write_samples(api, "parameter-write", "example-samples", [9, 10, 11])
            @test read_samples(api, "parameter-write", "example-samples") == [9.0, 10, 11]

            @test_throws Exception read_estimate(api, "object-write", "example-table")
            df = DataFrame(:a => [9, 10], :b => [11, 12])
            write_table(api, "object-write", "example-table", df)
            @test read_table(api, "object-write", "example-table") == df

            @test_throws Exception read_estimate(api, "object-write", "example-array")
            dimensions = [
                DataPipelineDimension(
                    title="dimension 1",
                    names=["column 1"],
                    values=[1],
                    units="dimension 1 units",
                )
            ]
            units = "array units"
            array = DataPipelineArray([4, 5, 6]; dimensions=dimensions, units=units)
            write_array(api, "object-write", "example-array", array)
            read_result = read_array(api, "object-write", "example-array")
            @test read_result == array

            @testset "Automatic array conversion" begin
                # Write a plain array, it should get transformed into the appropriate type
                array = [10.0, 11.0, 12.0]
                write_array(api, "object-write", "example-array", array)
                read_result = read_array(api, "object-write", "example-array")
                @test read_result == DataPipelineArray(array)
            end
        end
    end

    mktempdir() do tempdir
        datadir = mkdir(joinpath(tempdir, "data"))
        config = joinpath(datadir, "config.yaml")
        accessfile = joinpath(datadir, "access-simulationdata.yaml")
        remove_accessfile() = rm(accessfile, force=true)

        # Fresh copy of data for each testset because we will be writing stuff
        @testset "Basic syntax" begin
            cp("data", datadir; force=true)
            remove_accessfile()
            # Need to specify URI and git sha
            @test_throws MethodError StandardAPI(config)
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
