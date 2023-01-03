@testset "plot.jl" begin
    # SimpleRandomSample
    apisrs = load_data("apisrs")
    srs = SurveyDesign(apisrs, weights=:pw)
    s = plot(srs, :api99, :api00)
    @test s.grid[1].entries[1].named[:markersize] == srs.data.weights
    @test s.grid[1].entries[1].positional[1] == srs.data.api99
    @test s.grid[1].entries[1].positional[2] == srs.data.api00
    # StratifiedSample
end
