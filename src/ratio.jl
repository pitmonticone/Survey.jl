"""
    ratio(numerator, denominator, design)

Estimate the ratio of the columns specified in numerator and denominator.

```jldoctest
julia> apiclus1 = load_data("apiclus1");

julia> clus_one_stage = SurveyDesign(apiclus1; clusters = :dnum, weights = :pw) |> bootweights;

julia> ratio(:api00, :enroll, clus_one_stage)
1×2 DataFrame
 Row │ ratio    SE
     │ Float64  Float64
─────┼───────────────────
   1 │ 1.17182  0.131518

```
"""
function ratio(variable_num::Symbol, variable_den::Symbol, design::ReplicateDesign)
    X = wsum(design.data[!, variable_num], design.data[!, design.weights]) / wsum(design.data[!, variable_den], design.data[!, design.weights])
    Xt = [(wsum(design.data[!, variable_num], weights(design.data[! , "replicate_"*string(i)]))) / (wsum(design.data[!, variable_den], weights(design.data[! , "replicate_"*string(i)]))) for i in 1:design.replicates]
    variance = sum((Xt .- X).^2) / design.replicates
    DataFrame(ratio = X, SE = sqrt(variance))
end