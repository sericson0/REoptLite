
pyproj = pyimport("pyproj")

pth = dirname(@__FILE__)
push!(pyimport("sys")."path", pth)
pyscc = pyimport("sscapi")


function sam_wind_prod_factors(wind::Wind, time_steps_per_hour::Real, latitude::Float64, longitude::Float64)
    ssc_data = make_ssc(get_wind_data(wind, time_steps_per_hour, latitude, longitude)...)
    return wind_prod_factor(ssc_data)
end

function get_wind_data(wind::Wind, time_steps_per_hour::Real, latitude::Float64, longitude::Float64)
        # Parameters
        # ----------
        # path_inputs: string
        #     Path to folder where resource data should download
        # hub_height_meters: float
        #     The desired turbine height
        # elevation: float
        #     Site elevation in meters
        # latitude: float
        #     Site latitude
        #  longitude: float
        #     Site longitude
        #  year: int
        #     The year of resource data
        #  size_class: string
        #     The size class of the turbine
        #  temperature_celsius: list
        #     If passing in data directly, the list of temperatures at the hub height
        #  pressure_atmospheres: list
        #     If passing in data directly, the list of pressures at the hub height
        #  wind_meters_per_sec: list
        #     If passing in data directly, the list of wind speeds at the hub height
        #  wind_direction_degrees: list
        #     If passing in data directly, the list of directions at the hub height
        # time_steps_per_hour: float
        #     The time interval, eg. 1 is hourly, 0.5 half hour
        # file_resource_full: string
        #     Absolute path of filename (.srw file) with all heights necessary
        #
        #______________________________________________________________________
        #Reference Values
        allowed_hub_height_meters = [10, 40, 60, 80, 100, 120, 140, 160, 200]
        wind_turbine_powercurve_lookup = Dict("large" => [0, 0, 0, 70.119, 166.208, 324.625, 560.952, 890.771, 1329.664,
                                                    1893.213, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000,
                                                    2000, 2000, 2000, 2000, 2000, 2000],
                                          "medium"=> [0, 0, 0, 8.764875, 20.776, 40.578125, 70.119, 111.346375, 166.208,
                                                     236.651625, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250,
                                                     250, 250, 250, 250, 250],
                                          "commercial"=> [0, 0, 0, 3.50595, 8.3104, 16.23125, 28.0476, 44.53855, 66.4832,
                                                         94.66065, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
                                                         100, 100, 100, 100, 100],
                                          "residential"=> [0, 0, 0, 0.070542773, 0.1672125, 0.326586914, 0.564342188,
                                                          0.896154492, 1.3377, 1.904654883, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5,
                                                          2.5, 2.5, 2.5, 0, 0, 0, 0, 0, 0, 0])

        # """
        # Corresponding size in kW for generic reference turbines sizes
        # """
        system_capacity_lookup = Dict("large"=> 2000,
                                  "medium" => 250,
                                  "commercial"=> 100,
                                  "residential"=> 2.5)

        #
        # """
        # Corresponding rotor diameter in meters for generic reference turbines sizes
        # """
        rotor_diameter_lookup = Dict("large" => 55*2,
                                 "medium" => 21.9*2,
                                 "commercial" => 13.8*2,
                                 "residential" => 1.85*2)


        # Corresponding string interval name given a float time step in hours
        time_step_hour_to_minute_interval_lookup = Dict(
            1 =>  "60",
            0.5 => "30",
            0.25 => "15",
            round(5/60; digits = 2) => "5",
            round(1/60; digits = 2) => "1")
        #______________________________________________________________________

        d = Dict("wind_turbine_powercurve" => wind_turbine_powercurve_lookup[wind.size_class],
                 "system_capacity" => system_capacity_lookup[wind.size_class],
                 "rotor_diameter" => rotor_diameter_lookup[wind.size_class],
                 "latitude" => latitude,
                 "longitude" => longitude,
                 "year"=>wind.year,
                 "hub_height_meters" => wind.hub_height_meters
                 )

        interval = time_step_hour_to_minute_interval_lookup[time_steps_per_hour]

        file_downloaded = false
        if !isnothing(wind.file_resource_full)
            file_downloaded = isfile(wind.file_resource_full)
            if file_downloaded
                return false, wind.file_resource_full, d
            end
        end

        if (!isnothing(wind.temperature_celsius)) & (!isnothing(wind.pressure_atmospheres)) & (!isnothing(wind.wind_direction_degrees)) & (!isnothing(wind.wind_meters_per_sec))
            d["temperature_celsius"] = wind.temperature_celsius
            d["pressure_atmospheres"] = wind.pressure_atmospheres
            d["wind_direction_degrees"] = wind.wind_direction_degrees
            d["wind_meters_per_sec"] = wind.wind_meters_per_sec
            return true, nothing, d

        elseif isnothing(wind.file_resource_full) | (!file_downloaded)
            # evaluate hub height, determine what heights of resource data are required\
            hub_height_meters = wind.hub_height_meters

            heights = [hub_height_meters]
            if !(hub_height_meters in allowed_hub_height_meters)
                height_low = allowed_hub_height_meters[0]
                height_high = allowed_hub_height_meters[end]
                for h in allowed_hub_height_meters
                    if h < hub_height_meters
                        height_low = h
                    elseif h > hub_height_meters
                        height_high = h
                        break
                    end
                end
                heights[0] = height_low
                push!(heights, height_high)
            end
            # if there is no resource file passed in, create one
            file_resource_base = joinpath(wind.path_inputs, string(latitude) * "_" * string(longitude) * "_windtoolkit_" *
            string(wind.year) * "_" * string(interval) * "min")
            file_resource_full = file_resource_base
            # Regardless of whether file passed in, create the intermediate files required to download
            file_resource_heights = Dict()
            for h in heights
                file_resource_heights[h] = file_resource_base * "_" * string(h) * "m.srw"
                file_resource_full *= "_" * string(h) * "m"
            end
            file_resource_full *= ".srw"
            #If file doesnt exist then download it
            if !(isfile(file_resource_full))
                @info "Downloading wind data and saving to " file_resource_full
                for (height, f) in file_resource_heights
                    success = get_wind_resource_developer_api(f, wind.year, latitude, longitude, height)
                    if success == false
                        error("Unable to download wind data")
                    end
                end
                #TODO combine_wind_files
                # combine into one file to pass to SAM
                if length(heights) > 1
                    file_downloaded = combine_wind_files(file_resource_heights, file_resource_full)
                end
            end
        end
        return false, file_resource_full, d
end

#Function not checked. May have to change
function combine_wind_files(file_resource_heights::Dict, file_combined::String)
    data = [nothing, nothing]
    filenames = []
    for (height, f) in file_resource_heights
        push!(filenames, f)
    end
    dfs = DataFrame.(CSV.File(filenames))
    CSV.write(file_combined, dfs)
    return isfile(file_combined)
end




function make_ssc(use_input_data, file_resource_full, d)
    wind_turbine_speeds = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    """
    Function to set up the SAM run through the SAM Simulation Core
    """
    ssc = pyscc.PySSC()
    ssc.module_exec_set_print(0)
    data = ssc.data_create()
    wind_module = ssc.module_create("windpower")

    # must setup wind resource in its own ssc data structure
    wind_resource = []
    if use_input_data
        wind_resource = ssc.data_create()

        ssc.data_set_number(wind_resource, "latitude", d["latitude"])
        ssc.data_set_number(wind_resource, "longitude", d["longitude"])
        ssc.data_set_number(wind_resource, "elevation", 0)
        ssc.data_set_number(wind_resource, "year", d["year"])
        heights = [d["hub_height_meters"], d["hub_height_meters"], d["hub_height_meters"],
                            d["hub_height_meters"]]
        ssc.data_set_array(wind_resource, "heights", heights)
        fields = [1, 2, 3, 4]
        ssc.data_set_array(wind_resource, "fields", fields)
        data_matrix = []
        dm1 = transpose(hcat(d["temperature_celsius"], d["pressure_atmospheres"], d["wind_meters_per_sec"], d["wind_direction_degrees"]))
        for col in 1:size(dm1, 2)
            push!(data_matrix, dm1[:, col])
        end
        ssc.data_set_matrix(wind_resource, "data", data_matrix)

        ssc.data_set_table(data, "wind_resource_data", wind_resource)
    else
        ssc.data_set_string(data, "wind_resource_filename", file_resource_full)
    end
    ssc.data_set_number(data, "wind_resource_shear", 0.14000000059604645)
    ssc.data_set_number(data, "wind_resource_turbulence_coeff", 0.10000000149011612)
    ssc.data_set_number(data, "system_capacity", d["system_capacity"])
    ssc.data_set_number(data, "wind_resource_model_choice", 0)
    ssc.data_set_number(data, "weibull_reference_height", 50)
    ssc.data_set_number(data, "weibull_k_factor", 2)
    ssc.data_set_number(data, "weibull_wind_speed", 7.25)
    ssc.data_set_number(data, "wind_turbine_rotor_diameter", d["rotor_diameter"])
    ssc.data_set_array(data, "wind_turbine_powercurve_windspeeds", wind_turbine_speeds)
    ssc.data_set_array(data, "wind_turbine_powercurve_powerout", d["wind_turbine_powercurve"])
    ssc.data_set_number(data, "wind_turbine_hub_ht", d["hub_height_meters"])
    ssc.data_set_number(data, "wind_turbine_max_cp", 0.44999998807907104)
    wind_farm_xCoordinates = [0]
    ssc.data_set_array(data, "wind_farm_xCoordinates", wind_farm_xCoordinates)
    wind_farm_yCoordinates = [0]
    ssc.data_set_array(data, "wind_farm_yCoordinates", wind_farm_yCoordinates)
    ssc.data_set_number(data, "wind_farm_losses_percent", 0)
    ssc.data_set_number(data, "wind_farm_wake_model", 0)
    ssc.data_set_number(data, "adjust:constant", 0)

    return (ssc = ssc, data = data, wind_module = wind_module, wind_resource = wind_resource, system_capacity = d["system_capacity"], use_input_data = use_input_data)
end


function  wind_prod_factor(inputs::NamedTuple)
# ssc, data, wind_module, wind_resource, system_capacity

    model_run = inputs.ssc.module_exec(inputs.wind_module, inputs.data)
    if  model_run == 0
        println("windpower simulation error")
        # idx = 1
        println(inputs.ssc.module_log(inputs.wind_module, 0))
        #TODO loop through logs dealing with utf-8 message types
        while !(isnothing(msg))
            # if type(msg) == bytes:
            println(Char(msg))
            msg = inputs.ssc.module_log(inputs.module, idx)
            idx = idx + 1
        end
            #     msg = msg.decode("utf-8")
            # print ("   : {}".format(msg))
    end
    inputs.ssc.module_free(inputs.wind_module)

    # the system_power output from SAMSDK is of same length as input (i.e. 35040 series for 4 times steps/hour)
    system_power = inputs.ssc.data_get_array(inputs.data, "gen")
    prod_factor_original = [power/inputs.system_capacity for power in system_power]
    inputs.ssc.data_free(inputs.data)
    if inputs.use_input_data
        inputs.ssc.data_free(inputs.wind_resource)
    end

    return prod_factor_original
    # subhourly (i.e 15 minute data)
    #TODO reimplement subhourly timesteps
    # if inputs.time_steps_per_hour >= 1:
    #     timesteps = []
    #     timesteps_base = range(0, 8760)
    #     for ts_b in timesteps_base:
    #         for step in range(0, inputs.time_steps_per_hour):
    #             timesteps.append(ts_b)
    #
    # # downscaled run (i.e 288 steps per year)
    # else:
    #     timesteps = range(0, 8760, int(1 / inputs.time_steps_per_hour))
end

function get_conic_coords(lat, lng)
    WTK_ORIGIN = (-123.30661, 19.624062)
    # WTK_ORIGIN = (19.624062, -123.30661) #Original
    WTK_SHAPE = (1602, 2976)
    # """
    # Convert latitude, longitude into integer values for wind tool kit database.
    # Modified from "indicesForCoord" in https://github.com/NREL/hsds-examples/blob/master/notebooks/01_introduction.ipynb
    # Questions? Perr-Sauer, Jordan <Jordan.Perr-Sauer@nrel.gov>
    # :param db_conn: h5pyd.File, database connection
    # :param latitude:
    # :param longitude:
    # :return: (y, x) values to index into db_conn
    # """
    #dset = h5pyd.File("/nrel/wtk-us.h5", "r")["coordinates"]

    projstring = """+proj=lcc +lat_1=30 +lat_2=60
                    +lat_0=38.47240422490422 +lon_0=-96.0
                    +x_0=0 +y_0=0 +ellps=sphere
                    +units=m +no_defs """
    projectLcc = pyproj.Proj(projstring)
    # origin_ll = reverse(WTK_ORIGIN)  # to grab origin directly from database
    origin = projectLcc(origin_ll[1], origin_ll[2])
    point = projectLcc(lng, lat)
    delta = point .- origin
    println(delta)
    x,y = [Int(round(x / 2000)) for x in delta]
    y_max, x_max = WTK_SHAPE # dset.shape to grab shape directly  from database
    if (x<0) | (y<0) | (x>=x_max) | (y>=y_max)
        println(x)
        println(y)
        error("Latitude/Longitude is outside of wind resource dataset bounds.")
    end
    return y,x
end



function get_wind_resource_developer_api(filename, year, latitude, longitude, hub_height_meters)
    api_key="gAfosXcQ9Ldfw3qXqvKVb7PxMEkYigozmC9R3mXQ"

    url = "https://developer.nrel.gov/api/wind-toolkit/v2/wind/wtk-srw-download?year="*string(year)*"&lat="*string(latitude)*"&lon="*string(longitude)*"&hubheight="*string(hub_height_meters)*"&api_key="*string(api_key)
        """
        Parameters
        ---------
        url: string
            The API endpoint to return data from
        filename: string
            The filename where data should be written
        """
        # s = requests.Session()
        # n_max_tries = 5
        # retries = Retry(total=n_max_tries,
        #             backoff_factor=0.1,
        #             status_forcelist=[ 500, 502, 503, 504 ])
        #
        # s.mount("https://", HTTPAdapter(max_retries=retries))

        try
            r = HTTP.get(url)

            if r.status < 200 | r.status > 300
                # log.error("Wind Toolkit returned invalid data, HTTP " + str(r.status))
                error("Wind Toolkit returned invalid data, HTTP " + str(r.status))
            else
                open(filename, "w") do io
                    write(io, r.body)
                end
            end

        catch
            # log.error("Wind data download timed out " + str(n_max_tries) + "times")
            error("Wind Dataset Timed Out")
        end
    return true
end
