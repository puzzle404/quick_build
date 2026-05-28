require 'rails_helper'

RSpec.describe QuickbuildHelper, type: :helper do
  describe '#qb_fmt_ars' do
    it 'formats millions as "$ X.XM"' do
      expect(helper.qb_fmt_ars(2_500_000)).to eq('$ 2.5M')
    end

    it 'formats thousands as "$ Xk"' do
      expect(helper.qb_fmt_ars(45_000)).to eq('$ 45k')
    end

    it 'formats sub-thousands as "$ X"' do
      expect(helper.qb_fmt_ars(800)).to eq('$ 800')
    end

    it 'returns em dash for nil' do
      expect(helper.qb_fmt_ars(nil)).to eq('—')
    end

    it 'falls back to full format when mode is :full' do
      expect(helper.qb_fmt_ars(12_345_678, mode: :full)).to eq('$ 12.345.678')
    end
  end

  describe '#qb_fmt_pct' do
    it 'rounds and appends %' do
      expect(helper.qb_fmt_pct(63.7)).to eq('64%')
    end

    it 'returns em dash for nil' do
      expect(helper.qb_fmt_pct(nil)).to eq('—')
    end
  end

  describe '#qb_fmt_date_short' do
    it 'returns short es-AR date' do
      expect(helper.qb_fmt_date_short(Date.new(2026, 4, 18))).to match(/18 abr/i)
    end

    it 'returns em dash for nil' do
      expect(helper.qb_fmt_date_short(nil)).to eq('—')
    end
  end

  describe '#qb_fmt_cents' do
    it 'converts cents to compact ARS' do
      expect(helper.qb_fmt_cents(2_500_000_00)).to eq('$ 2.5M')
    end
  end

  describe '#qb_tone_class' do
    it 'maps tones to text classes' do
      expect(helper.qb_tone_class(:ok)).to eq('text-ok')
      expect(helper.qb_tone_class('warn')).to eq('text-warn')
    end

    it 'falls back to muted for unknown tones' do
      expect(helper.qb_tone_class(:nonexistent)).to eq('text-ink-3')
    end
  end
end
