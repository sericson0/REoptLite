using Test, JuMP, Cbc, JSON

cd(joinpath(dirname(dirname(@__FILE__)), "src"))
cd(dirname(dirname(@__FILE__)))
Pkg.activate(".")

include("../REoptLite.jl")

@testset "Wind Module" begin
    model = Model(optimizer_with_attributes(Cbc.Optimizer, "logLevel"=>0))
    data = JSON.parsefile("./scenarios/wind.json")
    s = Scenario(data)
    inputs = REoptInputs(s)
    results = run_reopt(model, inputs)

    @test results["Wind"]["size_kw"] ≈ 3746.4 atol=0.01 #A little bigger than the REopt Lite API size of 3735. Investigating why
    @test results["Financial"]["lcc_us_dollars"] ≈ 8577921 rtol=1e3 # Close but slightly different than REopt API of 8551172
    @test results["Financial"]["net_capital_costs_plus_om_us_dollars"] ≈ 8.56364e6 rtol=1e3  #net_capital_costs_plus_om 8537480 in REopt API
end


@testset "Wind Production Factor Download" begin
    path_inputs = joinpath(dirname(@__FILE__), "wind_resource")
    import CSV
    using DataFrames
    df = CSV.read(joinpath(path_inputs, "wind_data.csv"), DataFrame)
    d = Dict()
    d[:hub_height_meters] = 80
    d[:size_class] = "medium"
    d[:path_inputs] = path_inputs
    d[:temperature_celsius] = df.temperature
    d[:pressure_atmospheres] = df.pressure_100m
    d[:wind_meters_per_sec] = df.windspeed
    d[:wind_direction_degrees] = df.winddirection
    d[:year] = 2012
    wind = Wind(;d...)
    prod_factors = sam_wind_prod_factors(wind, 1, 39.91065, -105.2348)
    @test all(round(prod_factors[x], digits = 2) == round(df.prod_factor[x], digits = 2)  for x in 1:8760)
end
