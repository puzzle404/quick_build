import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { payload: Object }

  connect() {
    console.log('TwoLinesChartController connected')
    const payload = this.payloadValue || {}
    // Fallbacks por si payload viene vacío, para validar render
    const defaultLabels = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio']
    const labels = (payload.labels && payload.labels.length > 0) ? payload.labels : defaultLabels
    const series = (payload.series && payload.series.length > 0) ? payload.series : [
      {
        label: 'Etapas iniciadas',
        data: [12000, 15000, 18000, 16000, 20000, 25000],
        borderColor: '#4f46e5',
        backgroundColor: 'rgba(79, 70, 229, 0.1)'
      },
      {
        label: 'Etapas finalizadas',
        data: [14000, 17000, 19000, 21000, 23000, 28000],
        borderColor: '#16a34a',
        backgroundColor: 'rgba(22, 163, 74, 0.1)'
      }
    ]

    const canvas = this.element.querySelector('#myChart')
    console.log('canvads', canvas)
    if (!canvas) return

    const data = {
      labels: labels,
      datasets: series.map(s => ({
        label: s.label,
        data: s.data || [],
        borderColor: s.borderColor || '#4f46e5',
        backgroundColor: s.backgroundColor || 'rgba(79, 70, 229, 0.1)',
        borderWidth: 2,
        tension: 0.4,
        fill: true,
        pointRadius: 4,
        pointBackgroundColor: s.borderColor || '#4f46e5'
      }))
    }

    const config = {
      type: 'line',
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            labels: { color: '#334155', font: { size: 13 } },
          },
          tooltip: {
            mode: 'index',
            intersect: false,
          },
        },
        interaction: {
          mode: 'nearest',
          axis: 'x',
          intersect: false,
        },
        scales: {
          x: {
            ticks: { color: '#64748b' },
            grid: { color: '#f1f5f9' },
          },
          y: {
            beginAtZero: true,
            ticks: { color: '#64748b' },
            grid: { color: '#f1f5f9' },
          },
        },
      },
    }

    const start = () => {
      if (window.Chart) {
        this.chart = new Chart(canvas, config)
        return true
      }
      return false
    }

    if (!start()) {
      // Retry a few times in case CDN script loads after Stimulus connects
      let attempts = 0
      const iv = setInterval(() => {
        attempts += 1
        if (start() || attempts > 20) {
          clearInterval(iv)
        }
      }, 100)
    }
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }
}
