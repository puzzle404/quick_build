# frozen_string_literal: true

require "view_component/test_helpers"
require "capybara/rspec"
require "rails_helper"

RSpec.describe Ui::SearchPanelComponent, type: :component do
  include ViewComponent::TestHelpers
  include Capybara::RSpecMatchers

  let(:url) { "/search" }

  it "renders with explicit placeholder and no date fields by default" do
    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        query_value: "arena",
        placeholder: "Buscar obras..."
      )
    )

    expect(rendered_content).to have_css("form[action='#{url}']")
    expect(rendered_content).to have_css("input[type='text'][name='q'][id='search-panel-q'][placeholder='Buscar obras...']")
    expect(rendered_content).to have_no_css("input[type='date']")
  end

  it "shows date range inputs when date_filters are enabled" do
    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        query_value: nil,
        date_filters: {
          enabled: true,
          from_param: :from_date,
          to_param: :to_date,
          from_value: Date.new(2025, 1, 1),
          to_value: Date.new(2025, 1, 31),
          from_label: "Desde",
          to_label: "Hasta"
        }
      )
    )

    expect(rendered_content).to have_css("input[type='date'][name='from_date']")
    expect(rendered_content).to have_css("input[type='date'][name='to_date']")
  end

  it "computes placeholder via rules when provided and param matches" do
    allow_any_instance_of(described_class).to receive(:request_params).and_return({
      "view" => "sub_stages"
    })

    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        query_value: nil,
        placeholder_rules: { param: :view, map: { "sub_stages" => "Buscar subetapas..." }, default: "Buscar etapas..." }
      )
    )

    expect(rendered_content).to have_css("input[placeholder='Buscar subetapas...']")
  end

  it "uses explicit placeholder over rules when both are provided" do
    allow_any_instance_of(described_class).to receive(:request_params).and_return({
      "view" => "sub_stages"
    })

    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        placeholder: "Buscar personalizado...",
        placeholder_rules: { param: :view, map: { "sub_stages" => "Buscar subetapas..." }, default: "Buscar etapas..." }
      )
    )

    expect(rendered_content).to have_css("input[placeholder='Buscar personalizado...']")
  end

  it "falls back to default of rules when no match, then to generic default" do
    allow_any_instance_of(described_class).to receive(:request_params).and_return({
      "view" => "unknown"
    })

    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        placeholder_rules: { param: :view, map: { "sub_stages" => "Buscar subetapas..." }, default: "Buscar etapas..." }
      )
    )

    expect(rendered_content).to have_css("input[placeholder='Buscar etapas...']")

    # Now without rules at all, it should use the generic default
    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q
      )
    )
    expect(rendered_content).to have_css("input[placeholder='Buscar por nombre, dirección o responsable...']")
  end

  it "merges explicit hidden params with preserved request params and skips active query param and blanks" do
    allow_any_instance_of(described_class).to receive(:request_params).and_return({
      "view" => "main",
      "main_q" => "etapas",
      "sub_q" => "",
      "from_date" => "2025-01-01",
      "to_date" => "2025-01-31"
    })

    render_inline(
      described_class.new(
        form_action: url,
        query_param: :main_q,
        query_value: "etapas",
        hidden_params: { extra: "1" },
        preserve_params: [:view, :main_q, :sub_q, :from_date, :to_date]
      )
    )

    # Preserved (excluding query_param :main_q and blank :sub_q)
    expect(rendered_content).to have_css("input[type='hidden'][name='view'][value='main']", visible: :all)
    expect(rendered_content).to have_css("input[type='hidden'][name='from_date'][value='2025-01-01']", visible: :all)
    expect(rendered_content).to have_css("input[type='hidden'][name='to_date'][value='2025-01-31']", visible: :all)
    expect(rendered_content).to have_no_css("input[type='hidden'][name='main_q']", visible: :all)
    expect(rendered_content).to have_no_css("input[type='hidden'][name='sub_q']", visible: :all)

    # Explicit
    expect(rendered_content).to have_css("input[type='hidden'][name='extra'][value='1']", visible: :all)
  end

  it "supports preserve_params hash mapping to rename hidden fields" do
    allow_any_instance_of(described_class).to receive(:request_params).and_return({
      "foo" => "123"
    })

    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        preserve_params: { "foo" => "bar" }
      )
    )

    expect(rendered_content).to have_css("input[type='hidden'][name='bar'][value='123']", visible: :all)
  end

  it "excludes the active query param even when present in preserve_params mapping" do
    allow_any_instance_of(described_class).to receive(:request_params).and_return({
      "q" => "hola"
    })

    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        preserve_params: { q: :query }
      )
    )

    expect(rendered_content).to have_no_css("input[type='hidden'][name='query']", visible: :all)
  end

  it "exposes turbo frame and debounce via data attributes on form" do
    render_inline(
      described_class.new(
        form_action: url,
        query_param: :q,
        turbo_frame: "planning_results",
        debounce: 500
      )
    )

    expect(rendered_content).to have_css("form[data-controller='search-submit']")
    expect(rendered_content).to have_css("form[data-search-submit-delay-value='500']")
    expect(rendered_content).to have_css("form[data-turbo-frame='planning_results']")
  end
end
