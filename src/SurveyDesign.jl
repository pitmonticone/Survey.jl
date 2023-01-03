"""
    AbstractSurveyDesign

Supertype for every survey design type. 

!!! note

    The data passed to a survey constructor is modified. To avoid this pass a copy of the data
    instead of the original.
"""
abstract type AbstractSurveyDesign end

"""
    SurveyDesign <: AbstractSurveyDesign

Survey design sampled by one stage clusters sampling.
Clusters chosen by SRS followed by complete sampling of selected clusters.
Assumes each individual in one and only one clusters; disjoint and nested clusters.

`clusters` must be specified as a Symbol name of a column in `data`.

# Arguments:
`data::AbstractDataFrame`: the survey dataset (!this gets modified by the constructor).
`clusters::Symbol`: the stratification variable - must be given as a column in `data`.
`popsize::Union{Nothing,Symbol,<:Unsigned,Vector{<:Real}}=nothing`: the (expected) survey population size. For 

`weights::Union{Nothing,Symbol,Vector{<:Real}}=nothing`: the sampling weights.

```jldoctest
julia> apiclus1 = load_data("apiclus1");

julia> apiclus1[!, :pw] = fill(757/15,(size(apiclus1,1),)); # Correct api mistake for pw column

julia> dclus1 = SurveyDesign(apiclus1; clusters = :dnum, weights = :pw)
SurveyDesign:
data: 183x46 DataFrame
cluster: dnum
design.data[!,design.cluster]: 637, 637, 637, ..., 448
popsize: popsize
design.data[!,design.popsize]: 9240.0, 9240.0, 9240.0, ..., 9240.0
sampsize: sampsize
design.data[!,design.sampsize]: 15, 15, 15, ..., 15
design.data[!,:probs]: 0.0198, 0.0198, 0.0198, ..., 0.0198
design.data[!,:allprobs]: 0.0198, 0.0198, 0.0198, ..., 0.0198
```
"""
struct SurveyDesign <: AbstractSurveyDesign
    data::AbstractDataFrame
    cluster::Symbol
    popsize::Symbol
    sampsize::Symbol
    strata::Symbol
    pps::Bool
    # Single stage clusters sample, like apiclus1
    function SurveyDesign(data::AbstractDataFrame; strata::Union{Nothing,Symbol} = nothing, weights::Union{Nothing,Symbol}= nothing, clusters::Union{Nothing, Symbol, Vector{Symbol}} = nothing, popsize::Union{Nothing, Int,Symbol}=nothing) 
        # sampsize here is number of clusters completely sampled, popsize is total clusters in population
        if typeof(strata) <:Nothing
            data.false_strata = repeat(["FALSE_STRATA"], nrow(data))
            strata = :false_strata
        end
        if typeof(clusters) <: Nothing
            data.false_cluster = 1:nrow(data)
            cluster = :false_cluster
        end
        ## Single stage approximation
        if typeof(clusters) <: Vector{Symbol}
            cluster = first(clusters)
        end
        if typeof(clusters) <: Symbol
            cluster = clusters
        end
        # For one-stage sample only one sampsize vector
        sampsize_labels = :sampsize
        data[!, sampsize_labels] = fill(length(unique(data[!, cluster])),(nrow(data),))
        if !(typeof(popsize) <: Nothing)
            data[!, :weights] = data[!, popsize] ./ data[!, sampsize_labels]
        elseif !(typeof(weights) <: Nothing)
            data.weights = data[!, weights]
        else
            data.weights = repeat([1], nrow(data))
        end
        data[!, :probs] = 1 ./ data[!, :weights] # Many formulae are easily defined in terms of sampling probabilties
        data[!, :allprobs] = data[!, :probs] # In one-stage cluster sample, allprobs is just probs, no multiplication needed
        pps = false
        if !(typeof(popsize) <: Symbol)
            data.popsize = repeat([sum(data.weights)], nrow(data))
            popsize = :popsize
        end
        new(data, cluster, popsize, sampsize_labels, strata, pps)
    end
end

"""
```jldoctest
julia> apiclus1 = load_data("apiclus1");

julia> apiclus1[!, :pw] = fill(757/15,(size(apiclus1,1),)); # Correct api mistake for pw column

julia> dclus1 = SurveyDesign(apiclus1; clusters = :dnum, weights = :pw); 

julia> bclus1 = Survey.bootweights(dclus1; replicates = 1000)
Survey.ReplicateDesign:
data: 183x1046 DataFrame
cluster: dnum
design.data[!,design.cluster]: 637, 637, 637, ..., 448
popsize: popsize
design.data[!,design.popsize]: 9240.0, 9240.0, 9240.0, ..., 9240.0
sampsize: sampsize
design.data[!,design.sampsize]: 15, 15, 15, ..., 15
design.data[!,:probs]: 0.0198, 0.0198, 0.0198, ..., 0.0198
design.data[!,:allprobs]: 0.0198, 0.0198, 0.0198, ..., 0.0198
replicates: 1000
```
"""
struct ReplicateDesign <: AbstractSurveyDesign
    data::AbstractDataFrame
    cluster::Symbol
    popsize::Symbol
    sampsize::Symbol
    strata::Symbol
    pps::Bool
    replicates::UInt
end
