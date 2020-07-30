using Revise

using Genie.Router, Genie.Renderer.Html
using Stipple

using StippleUI, StippleUI.Table, StippleUI.Range, StippleUI.BigNumber, StippleUI.Heading, StippleUI.Dashboard
using StippleCharts, StippleCharts.Charts

import StippleUI.Range: range

using CSV, DataFrames


# configuration
const data_opts = DataTableOptions(columns = [Column("Good_Rating"), Column("Amount", align = :right),
                                              Column("Age", align = :right), Column("Duration", align = :right)])

const plot_colors = ["#72C8A9", "#BD5631"]

const bubble_plot_opts = PlotOptions(data_labels_enabled=false, fill_opacity=0.8, xaxis_tick_amount=10, chart_animations_enabled=false,
                                      xaxis_max=80, xaxis_min=17, yaxis_max=20_000, chart_type=:bubble,
                                      colors=plot_colors, plot_options_bubble_min_bubble_radius=4, chart_font_family="Lato, Helvetica, Arial, sans-serif")

const bar_plot_opts = PlotOptions(xaxis_tick_amount=10, xaxis_max=350, chart_type=:bar, plot_options_bar_data_labels_position=:top,
                                  plot_options_bar_horizontal=true, chart_height=200, colors=plot_colors, chart_animations_enabled=false,
                                  xaxis_categories = ["20-30", "30-40", "40-50", "50-60", "60-70", "70-80"], chart_toolbar_show=false,
                                  chart_font_family="Lato, Helvetica, Arial, sans-serif")


# model
data = CSV.File("data/german_credit.csv") |> DataFrame!

Base.@kwdef mutable struct Dashboard <: ReactiveModel
  credit_data::R{DataTable} = DataTable()
  credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=100)
  credit_data_loading::R{Bool} = false

  range_data::R{RangeData{Int}} = RangeData(15:80)

  big_numbers_count_good_credits::R{Int} = 0
  big_numbers_count_bad_credits::R{Int} = 0
  big_numbers_amount_good_credits::R{Int} = 0
  big_numbers_amount_bad_credits::R{Int} = 0

  bar_plot_options::PlotOptions = bar_plot_opts
  bar_plot_data::R{Vector{PlotSeries}} = []

  bubble_plot_options::PlotOptions = bubble_plot_opts
  bubble_plot_data::R{Vector{PlotSeries}} = []
end


# functions
function creditdata(data::DataFrame, model::M) where {M<:Stipple.ReactiveModel}
  model.credit_data[] = DataTable(data, data_opts)
end

function bignumbers(data::DataFrame, model::M) where {M<:ReactiveModel}
  model.big_numbers_count_good_credits[] = data[(data[:Good_Rating] .== true), [:Good_Rating]] |> nrow
  model.big_numbers_count_bad_credits[] = data[(data[:Good_Rating] .== false), [:Good_Rating]] |> nrow
  model.big_numbers_amount_good_credits[] = data[(data[:Good_Rating] .== true), [:Amount]] |> Array |> sum
  model.big_numbers_amount_bad_credits[] = data[(data[:Good_Rating] .== false), [:Amount]] |> Array |> sum
end

function barstats(data::DataFrame, model::M) where {M<:Stipple.ReactiveModel}
  age_stats = Dict{Symbol,Vector{Int}}(:good_credit => Int[], :bad_credit => Int[])

  for x in 20:10:70
    push!(age_stats[:good_credit],
          data[(data[:Age] .∈ [x:x+10]) .& (data[:Good_Rating] .== true), [:Good_Rating]] |> nrow)
    push!(age_stats[:bad_credit],
          data[(data[:Age] .∈ [x:x+10]) .& (data[:Good_Rating] .== false), [:Good_Rating]] |> nrow)
  end

  model.bar_plot_data[] = [PlotSeries("Good credit", PlotData(age_stats[:good_credit])),
                            PlotSeries("Bad credit", PlotData(age_stats[:bad_credit]))]
end

function bubblestats(data::DataFrame, model::M) where {M<:ReactiveModel}
  selected_columns = [:Age, :Amount, :Duration]
  credit_stats = Dict{Symbol,DataFrame}()

  credit_stats[:good_credit] = data[data[:Good_Rating] .== true, selected_columns]
  credit_stats[:bad_credit] = data[data[:Good_Rating] .== false, selected_columns]

  model.bubble_plot_data[] = [PlotSeries("Good credit", PlotData(credit_stats[:good_credit])),
                              PlotSeries("Bad credit", PlotData(credit_stats[:bad_credit]))]
end

function setmodel(data::DataFrame, model::M)::M where {M<:ReactiveModel}
  creditdata(data, model)
  bignumbers(data, model)

  barstats(data, model)
  bubblestats(data, model)

  model
end


### UI
Stipple.register_components(Dashboard, StippleCharts.COMPONENTS)

model = setmodel(data, Dashboard()) |> Stipple.init

function filterdata(model::Dashboard)
  model.credit_data_loading[] = true
  model = setmodel(data[(model.range_data[].range.start .<= data[:Age] .<= model.range_data[].range.stop), :], model)
  model.credit_data_loading[] = false

  nothing
end

function ui()
  dashboard(root(model), [
    heading("German Credits by Age")

    row([
      cell(class="st-module", [
        row([
          cell(class="st-br", [
            bignumber("Bad credits",
                      :big_numbers_count_bad_credits,
                      icon="format_list_numbered",
                      color="negative")
          ])

          cell(class="st-br", [
            bignumber("Good credits",
                      :big_numbers_count_good_credits,
                      icon="format_list_numbered",
                      color="positive")
          ])

          cell(class="st-br", [
            bignumber("Bad credits total amount",
                      R"big_numbers_amount_bad_credits | numberformat",
                      icon="euro_symbol",
                      color="negative")
          ])

          cell(class="st-br", [
            bignumber("Good credits total amount",
                      R"big_numbers_amount_good_credits | numberformat",
                      icon="euro_symbol",
                      color="positive")
          ])
        ])
      ])
    ])

    row([
      cell([
        h4("Age interval filter")

        range(18:1:90,
              :range_data;
              label=true,
              labelvalueleft="'Min age: ' + range_data.min",
              labelvalueright="'Max age: ' + range_data.max")
      ])
    ])

    row([
      cell(class="st-module", [
        h4("Credits data")

        table(:credit_data;
              style="height: 400px;",
              pagination=:credit_data_pagination,
              loading=:credit_data_loading
        )
      ])
      cell(class="st-module", [
        h4("Credits by age")
        plot(:bar_plot_data; options=:bar_plot_options)
      ])
    ])

    row([
      cell(class="st-module", [
        h4("Credits by age, amount and duration")
        plot(:bubble_plot_data; options=:bubble_plot_options)
      ])
    ])

    footer(class="st-footer q-pa-md", [
      cell([
        img(class="st-logo", src="/img/st-logo.svg")
        span(" &copy; 2020")
      ])
    ])
  ], title="German Credits by Age") |> html
end

# handlers
on(model.range_data) do _
  filterdata(model)
end

# routes
route("/", ui)

# JS deps
function __init__()
  push!(Stipple.DEPS, () -> script(src="/js/plugins/genie_autoreload/autoreload.js"))
end

# start server
up()