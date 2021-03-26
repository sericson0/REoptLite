function add_wind_results(m::JuMP.AbstractModel, p::REoptInputs, d::Dict; _n="")
	r = Dict{String, Any}()
	r["size_kw"] = round(value(m[Symbol("dvSize"*_n)]["Wind"]), digits = 4)
	if !isempty(p.storage.types)
		WindtoBatt = (sum(m[Symbol("dvProductionToStorage"*_n)][b, "Wind", ts] for b in p.storage.types) for ts in p.time_steps)
	else
		WindtoBatt = repeat([0], length(p.time_steps))
	end
	r["year_one_to_battery_series_kw"] = round.(value.(WindtoBatt), digits=3)

	WindtoNEM = (m[Symbol("dvNEMexport"*_n)]["Wind", ts] for ts in p.time_steps)
	r["WindtoNEM"] = round.(value.(WindtoNEM), digits=3)

	WindtoWHL = (m[Symbol("dvWHLexport"*_n)]["Wind", ts] for ts in p.time_steps)
	r["WindtoWHL"] = round.(value.(WindtoWHL), digits=3)

    r["year_one_to_grid_series_kw"] = r["WindtoWHL"] .+ r["WindtoNEM"]

	WindtoCUR = (m[Symbol("dvCurtail"*_n)]["Wind", ts] for ts in p.time_steps)
	r["year_one_curtailed_production_series_kw"] = round.(value.(WindtoCUR), digits=3)
	WindtoLoad = (m[Symbol("dvRatedProduction"*_n)]["Wind", ts] * p.production_factor["Wind", ts] * p.levelization_factor["Wind"]
				- r["year_one_curtailed_production_series_kw"][ts]
				- r["year_one_to_grid_series_kw"][ts]
				- r["year_one_to_battery_series_kw"][ts] for ts in p.time_steps
	)
	r["year_one_to_load_series_kw"] = round.(value.(WindtoLoad), digits=3)
	Year1WindProd = (sum(m[Symbol("dvRatedProduction"*_n)]["Wind",ts] * p.production_factor["Wind", ts] for ts in p.time_steps) * p.hours_per_timestep)
	r["year_one_energy_produced_kwh"] = round(value(Year1WindProd), digits=0)
	WindPerUnitSizeOMCosts = p.om_cost_per_kw["Wind"] * p.pwf_om * m[Symbol("dvSize"*_n)]["Wind"]
	r["total_om_cost_us_dollars"] = round(value(WindPerUnitSizeOMCosts) * (1 - p.owner_tax_pct), digits=0)
	r["wind_prod_factor"] = p.production_factor["Wind", :]
	r["capital_costs"] = p.cap_cost_slope["Wind"] * value(m[:dvPurchaseSize]["Wind"])
    d["Wind"] = r
    nothing
end
