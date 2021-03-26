struct Wind <: AbstractTech
    existing_kw
    min_kw
    max_kw
    acres_per_kw
    om_cost_per_kw
    macrs_option_years
    macrs_bonus_pct
    macrs_itc_reduction
    total_itc_pct
    total_rebate_per_kw
    cost_per_kw
    #For production factor
    file_resource_full
    path_inputs
    hub_height_meters
    size_class
    temperature_celsius
    pressure_atmospheres
    wind_direction_degrees
    wind_meters_per_sec
    year

    function Wind(;
        existing_kw::Float64 = 0.0,
        min_kw::Float64 = 0.0,
        max_kw::Real = 1.0e6,
        acres_per_kw::Float64 = 0.03,
        om_cost_per_kw::Float64=16.0,
        macrs_option_years::Int = 5,
        macrs_bonus_pct::Float64 = 1.0,
        macrs_itc_reduction::Float64 = 0.5,
        total_itc_pct::Float64 = 0.26,
        total_rebate_per_kw::Float64 = 0.0,
        cost_per_kw::Float64 = 0.0,
        file_resource_full::Union{String, Nothing} = nothing,
        path_inputs::String = joinpath(dirname(@__FILE__), "../../","wind data"),
        hub_height_meters::Int64 = 80,
        size_class::String = "large",
        temperature_celsius = nothing,
        pressure_atmospheres::Union{AbstractArray, Nothing} = nothing,
        wind_direction_degrees::Union{AbstractArray, Nothing} = nothing,
        wind_meters_per_sec::Union{AbstractArray, Nothing} = nothing,
        year::Int64 = 2011
        )

        new(
            existing_kw,
            min_kw,
            max_kw,
            acres_per_kw,
            om_cost_per_kw,
            macrs_option_years,
            macrs_bonus_pct,
            macrs_itc_reduction,
            total_itc_pct,
            total_rebate_per_kw,
            cost_per_kw,
            file_resource_full,
            path_inputs,
            hub_height_meters,
            size_class,
            temperature_celsius,
            pressure_atmospheres,
            wind_direction_degrees,
            wind_meters_per_sec,
            year
        )
    end
end
